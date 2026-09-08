import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/cloud_sync_config.dart';
import 'package:finance_app/services/cloud_sync_exception.dart';
import 'package:http/http.dart' as http;

/// S3 兼容存储（MinIO / R2 / OSS 等）的 PutObject / GetObject。
class S3BackupService {
  static const _requestTimeout = Duration(seconds: 15);
  static const _service = 's3';

  static Future<void> uploadBackup(
    S3BackupConfig config,
    AppBackupBundle bundle,
  ) async {
    final payload = utf8.encode(jsonEncode(bundle.toJson()));
    final response = await _signedRequest(
      config: config,
      method: 'PUT',
      body: payload,
      contentType: 'application/json',
      errorPrefix: 'S3 备份失败',
    );
    _ensureSuccess(response, defaultMessage: 'S3 备份失败');
  }

  static Future<AppBackupBundle> downloadBackup(S3BackupConfig config) async {
    final response = await _signedRequest(
      config: config,
      method: 'GET',
      errorPrefix: 'S3 下载失败',
    );
    _ensureSuccess(response, defaultMessage: 'S3 下载失败');
    return _parseBundle(
      response.body,
      emptyMessage: 'S3 对象为空，无法恢复',
      invalidMessage: 'S3 对象格式错误，无法恢复',
    );
  }

  static Future<AppBackupBundle?> fetchRemoteBundleMeta(
    S3BackupConfig config,
  ) async {
    final response = await _signedRequest(
      config: config,
      method: 'GET',
      errorPrefix: '读取远端备份信息失败',
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response, defaultMessage: '读取远端备份信息失败');
    if (response.body.trim().isEmpty) {
      return null;
    }
    try {
      return _parseBundle(
        response.body,
        emptyMessage: 'S3 对象为空',
        invalidMessage: 'S3 对象格式无效',
      );
    } on CloudSyncException {
      return null;
    }
  }

  static Future<http.Response> _signedRequest({
    required S3BackupConfig config,
    required String method,
    List<int>? body,
    String? contentType,
    required String errorPrefix,
  }) async {
    final endpointUri = _parseEndpoint(config.endpoint);
    final objectKey = _normalizeObjectKey(config.objectKey);
    final canonicalUri = _canonicalUri(config, objectKey);

    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = amzDate.substring(0, 8);
    final payloadHash = sha256.convert(body ?? const <int>[]).toString();
    final hostHeader = _hostHeader(endpointUri, config);

    final headers = <String, String>{
      'host': hostHeader,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'content-type': ?contentType,
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
      'content-type': ?contentType,
      'Authorization': authorization,
      'Accept': 'application/json',
    };

    final requestUri = Uri(
      scheme: endpointUri.scheme.isEmpty ? 'https' : endpointUri.scheme,
      host: _requestHost(endpointUri, config),
      port: endpointUri.hasPort ? endpointUri.port : null,
      path: canonicalUri,
    );

    try {
      if (method == 'PUT') {
        return await http
            .put(requestUri, headers: requestHeaders, body: body)
            .timeout(_requestTimeout);
      }
      if (method == 'GET') {
        return await http
            .get(requestUri, headers: requestHeaders)
            .timeout(_requestTimeout);
      }
      throw CloudSyncException('$errorPrefix：不支持的方法 $method');
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

  static Uri _parseEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    if (uri.host.isEmpty) {
      throw const FormatException('invalid endpoint');
    }
    return uri;
  }

  static String _normalizeObjectKey(String objectKey) {
    var key = objectKey.trim();
    while (key.startsWith('/')) {
      key = key.substring(1);
    }
    return key;
  }

  static String _requestHost(Uri endpointUri, S3BackupConfig config) {
    if (config.forcePathStyle) {
      return endpointUri.host;
    }
    return '${config.bucket.trim()}.${endpointUri.host}';
  }

  static String _hostHeader(Uri endpointUri, S3BackupConfig config) {
    final host = _requestHost(endpointUri, config);
    if (endpointUri.hasPort &&
        endpointUri.port != 80 &&
        endpointUri.port != 443) {
      return '$host:${endpointUri.port}';
    }
    return host;
  }

  static String _canonicalUri(S3BackupConfig config, String objectKey) {
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

  static List<int> _signingKey({
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

  static String _formatAmzDate(DateTime utc) {
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

  static AppBackupBundle _parseBundle(
    String body, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    if (body.trim().isEmpty) {
      throw CloudSyncException(emptyMessage);
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw CloudSyncException(invalidMessage);
    }
    if (decoded is! Map) {
      throw CloudSyncException(invalidMessage);
    }
    return AppBackupBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  static void _ensureSuccess(
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
      message = '$defaultMessage：远端对象不存在，请先执行备份';
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
