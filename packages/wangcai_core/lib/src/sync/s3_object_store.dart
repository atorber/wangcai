import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:wangcai_core/src/models/cloud_sync_config.dart';
import 'package:wangcai_core/src/sync/cloud_sync_exception.dart';
import 'package:wangcai_core/src/sync/object_store.dart';

/// S3 兼容 [ObjectStore]（MinIO / R2 / OSS 等），[path] 为 object key（不含 bucket）。
class S3ObjectStore implements ObjectStore {
  S3ObjectStore(this.config, {http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _requestTimeout = Duration(seconds: 15);
  static const _service = 's3';

  final S3BackupConfig config;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<void> put(String path, List<int> bytes, {String? contentType}) async {
    final response = await _signedRequest(
      method: 'PUT',
      objectKey: path,
      body: bytes,
      contentType: contentType,
      errorPrefix: 'S3 上传失败',
    );
    _ensureSuccess(response, defaultMessage: 'S3 上传失败');
  }

  @override
  Future<bool> putIfAbsent(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    final response = await _signedRequest(
      method: 'PUT',
      objectKey: path,
      body: bytes,
      contentType: contentType,
      extraHeaders: const {'If-None-Match': '*'},
      errorPrefix: 'S3 条件上传失败',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    if (response.statusCode == 412 ||
        response.statusCode == 409 ||
        _isPreconditionFailed(response)) {
      return false;
    }

    if (_looksLikeUnsupportedPrecondition(response)) {
      return _putIfAbsentFallback(path, bytes, contentType: contentType);
    }

    _ensureSuccess(response, defaultMessage: 'S3 条件上传失败');
    return true;
  }

  Future<bool> _putIfAbsentFallback(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    final existing = await head(path);
    if (existing != null) {
      return false;
    }
    await put(path, bytes, contentType: contentType);
    return true;
  }

  @override
  Future<List<int>?> get(String path) async {
    final response = await _signedRequest(
      method: 'GET',
      objectKey: path,
      errorPrefix: 'S3 下载失败',
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response, defaultMessage: 'S3 下载失败');
    return response.bodyBytes;
  }

  @override
  Future<ObjectMeta?> head(String path) async {
    final response = await _signedRequest(
      method: 'HEAD',
      objectKey: path,
      errorPrefix: 'S3 HEAD 失败',
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode == 405 || response.statusCode == 501) {
      final getResponse = await _signedRequest(
        method: 'GET',
        objectKey: path,
        errorPrefix: 'S3 读取元数据失败',
      );
      if (getResponse.statusCode == 404) {
        return null;
      }
      _ensureSuccess(getResponse, defaultMessage: 'S3 读取元数据失败');
      return _metaFromHeaders(
        getResponse.headers,
        getResponse.bodyBytes.length,
      );
    }
    _ensureSuccess(response, defaultMessage: 'S3 HEAD 失败');
    return _metaFromHeaders(response.headers, response.contentLength);
  }

  @override
  Future<void> delete(String path) async {
    final response = await _signedRequest(
      method: 'DELETE',
      objectKey: path,
      errorPrefix: 'S3 删除失败',
    );
    if (response.statusCode == 404) {
      return;
    }
    _ensureSuccess(response, defaultMessage: 'S3 删除失败');
  }

  Future<http.Response> _signedRequest({
    required String method,
    required String objectKey,
    List<int>? body,
    String? contentType,
    Map<String, String>? extraHeaders,
    required String errorPrefix,
  }) async {
    final endpointUri = _parseEndpoint(config.endpoint);
    final key = _normalizeObjectKey(objectKey);
    final canonicalUri = _canonicalUri(key);

    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = amzDate.substring(0, 8);
    final payloadHash = sha256.convert(body ?? const <int>[]).toString();
    final hostHeader = _hostHeader(endpointUri);

    final headers = <String, String>{
      'host': hostHeader,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (contentType != null) 'content-type': contentType,
      if (extraHeaders != null)
        for (final entry in extraHeaders.entries)
          entry.key.toLowerCase(): entry.value,
    };

    final signedHeaderNames = headers.keys.map((e) => e.toLowerCase()).toList()
      ..sort();
    final canonicalHeaders = signedHeaderNames
        .map((name) => '$name:${headers[name]!.trim()}\n')
        .join();
    final signedHeaders = signedHeaderNames.join(';');

    final canonicalRequest = [
      method,
      canonicalUri,
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope =
        '$dateStamp/${config.region.trim()}/$_service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    final signingKey = _signingKey(
      secretAccessKey: config.secretAccessKey.trim(),
      dateStamp: dateStamp,
      region: config.region.trim(),
    );
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'AWS4-HMAC-SHA256 Credential=${config.accessKeyId.trim()}/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    final requestHeaders = <String, String>{
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (contentType != null) 'content-type': contentType,
      if (extraHeaders != null) ...extraHeaders,
      'Authorization': authorization,
      'Accept': '*/*',
    };

    final requestUri = Uri(
      scheme: endpointUri.scheme.isEmpty ? 'https' : endpointUri.scheme,
      host: _requestHost(endpointUri),
      port: endpointUri.hasPort ? endpointUri.port : null,
      path: canonicalUri,
    );

    try {
      switch (method) {
        case 'PUT':
          return await _client
              .put(requestUri, headers: requestHeaders, body: body)
              .timeout(_requestTimeout);
        case 'GET':
          return await _client
              .get(requestUri, headers: requestHeaders)
              .timeout(_requestTimeout);
        case 'HEAD':
        case 'DELETE':
          final request = http.Request(method, requestUri)
            ..headers.addAll(requestHeaders);
          final streamed = await _client
              .send(request)
              .timeout(_requestTimeout);
          return http.Response.fromStream(streamed);
        default:
          throw CloudSyncException('$errorPrefix：不支持的方法 $method');
      }
    } on http.ClientException catch (e) {
      throw CloudSyncException('$errorPrefix：网络连接异常（${e.message}）');
    } on FormatException {
      throw CloudSyncException('$errorPrefix：Endpoint 格式错误');
    } on CloudSyncException {
      rethrow;
    } catch (_) {
      throw CloudSyncException('$errorPrefix：请求超时或网络异常');
    }
  }

  Uri _parseEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    if (uri.host.isEmpty) {
      throw const FormatException('invalid endpoint');
    }
    return uri;
  }

  String _normalizeObjectKey(String objectKey) {
    var key = objectKey.trim();
    while (key.startsWith('/')) {
      key = key.substring(1);
    }
    return key;
  }

  String _requestHost(Uri endpointUri) {
    if (config.forcePathStyle) {
      return endpointUri.host;
    }
    return '${config.bucket.trim()}.${endpointUri.host}';
  }

  String _hostHeader(Uri endpointUri) {
    final host = _requestHost(endpointUri);
    if (endpointUri.hasPort &&
        endpointUri.port != 80 &&
        endpointUri.port != 443) {
      return '$host:${endpointUri.port}';
    }
    return host;
  }

  String _canonicalUri(String objectKey) {
    final encodedKey = objectKey
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    if (config.forcePathStyle) {
      return '/${Uri.encodeComponent(config.bucket.trim())}/$encodedKey';
    }
    return '/$encodedKey';
  }

  List<int> _signingKey({
    required String secretAccessKey,
    required String dateStamp,
    required String region,
  }) {
    final kDate = Hmac(
      sha256,
      utf8.encode('AWS4$secretAccessKey'),
    ).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(region)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(_service)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  }

  String _formatAmzDate(DateTime utc) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}'
        '${two(utc.month)}'
        '${two(utc.day)}'
        'T'
        '${two(utc.hour)}'
        '${two(utc.minute)}'
        '${two(utc.second)}'
        'Z';
  }

  ObjectMeta _metaFromHeaders(Map<String, String> headers, int? contentLength) {
    final etag = headers['etag'] ?? headers['ETag'];
    final lastModifiedRaw =
        headers['last-modified'] ?? headers['Last-Modified'];
    final lengthHeader = headers['content-length'] ?? headers['Content-Length'];
    return ObjectMeta(
      etag: etag,
      lastModified: lastModifiedRaw == null
          ? null
          : DateTime.tryParse(lastModifiedRaw)?.toUtc(),
      contentLength: lengthHeader == null
          ? contentLength
          : int.tryParse(lengthHeader) ?? contentLength,
    );
  }

  bool _isPreconditionFailed(http.Response response) {
    final body = response.body.toLowerCase();
    return body.contains('precondition') ||
        body.contains('if-none-match') ||
        response.statusCode == 412;
  }

  bool _looksLikeUnsupportedPrecondition(http.Response response) {
    final code = response.statusCode;
    if (code == 400 || code == 501 || code == 405 || code == 422) {
      return true;
    }
    // 部分兼容实现忽略 If-None-Match 仍返回 200；无法可靠检测，由调用方自行 Head 校验。
    // 这里仅在明确不支持时走 fallback。
    final body = response.body.toLowerCase();
    return body.contains('unknown header') ||
        body.contains('unsupported') ||
        body.contains('not implemented');
  }

  void _ensureSuccess(
    http.Response response, {
    required String defaultMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final code = response.statusCode;
    String message = defaultMessage;
    if (code == 401 || code == 403) {
      message = '$defaultMessage：认证失败，请检查 Access Key / Secret';
    } else if (code == 404) {
      message = '$defaultMessage：远端对象不存在';
    } else if (code == 409) {
      message = '$defaultMessage：远端路径冲突，请检查 Bucket / Object Key';
    } else if (code >= 500) {
      message = '$defaultMessage：服务器异常（$code）';
    } else {
      message = '$defaultMessage：HTTP $code';
    }
    throw CloudSyncException(message, statusCode: code);
  }
}
