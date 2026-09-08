import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wangcai_core/src/models/cloud_sync_config.dart';
import 'package:wangcai_core/src/sync/cloud_sync_exception.dart';
import 'package:wangcai_core/src/sync/object_store.dart';

/// WebDAV [ObjectStore]，路径为远端绝对路径（由 [WebDavBackupConfig.serverUrl] 拼接）。
class WebDavObjectStore implements ObjectStore {
  WebDavObjectStore(this.config, {http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _requestTimeout = Duration(seconds: 45);

  final WebDavBackupConfig config;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<void> put(String path, List<int> bytes, {String? contentType}) async {
    await _ensureParentDirectories(path);
    final response = await _guardRequest(
      () => _client.put(
        _buildUri(path),
        headers: _headers(contentType: contentType),
        body: bytes,
      ),
      errorPrefix: 'WebDAV 上传失败',
    );
    _ensureSuccess(response, defaultMessage: 'WebDAV 上传失败');
  }

  @override
  Future<bool> putIfAbsent(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    await _ensureParentDirectories(path);

    // 坚果云等会忽略 If-None-Match:* 仍返回 2xx 并覆盖文件，因此必须先探测存在性。
    // 先 GET：已存在则视为未创建（锁被占用）。
    final probe = await _guardRequest(
      () => _client.get(_buildUri(path), headers: _headers()),
      errorPrefix: 'WebDAV 读取失败',
    );
    if (probe.statusCode == 200) {
      return false;
    }
    if (probe.statusCode != 404 &&
        probe.statusCode != 405 &&
        probe.statusCode != 409) {
      _ensureSuccess(probe, defaultMessage: 'WebDAV 读取失败');
    }

    final conditional = await _guardRequest(
      () => _client.put(
        _buildUri(path),
        headers: {
          ..._headers(contentType: contentType),
          'If-None-Match': '*',
        },
        body: bytes,
      ),
      errorPrefix: 'WebDAV 条件上传失败',
    );

    if (conditional.statusCode == 412 || conditional.statusCode == 409) {
      return false;
    }
    if (conditional.statusCode == 200 ||
        conditional.statusCode == 201 ||
        conditional.statusCode == 204) {
      return true;
    }

    // 服务端不支持 If-None-Match 时回退：再 GET，404 再 PUT。
    if (_looksLikeUnsupportedPrecondition(conditional.statusCode)) {
      return _putIfAbsentFallback(path, bytes, contentType: contentType);
    }

    _ensureSuccess(conditional, defaultMessage: 'WebDAV 条件上传失败');
    return true;
  }

  Future<bool> _putIfAbsentFallback(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    final existing = await _guardRequest(
      () => _client.get(_buildUri(path), headers: _headers()),
      errorPrefix: 'WebDAV 读取失败',
    );
    if (existing.statusCode == 200) {
      return false;
    }
    if (existing.statusCode != 404 &&
        existing.statusCode != 405 &&
        existing.statusCode != 409) {
      _ensureSuccess(existing, defaultMessage: 'WebDAV 读取失败');
    }
    final response = await _guardRequest(
      () => _client.put(
        _buildUri(path),
        headers: _headers(contentType: contentType),
        body: bytes,
      ),
      errorPrefix: 'WebDAV 上传失败',
    );
    _ensureSuccess(response, defaultMessage: 'WebDAV 上传失败');
    return true;
  }

  @override
  Future<List<int>?> get(String path) async {
    final response = await _guardRequest(
      () => _client.get(_buildUri(path), headers: _headers()),
      errorPrefix: 'WebDAV 下载失败',
    );
    if (response.statusCode == 404 ||
        response.statusCode == 405 ||
        response.statusCode == 409) {
      return null;
    }
    _ensureSuccess(response, defaultMessage: 'WebDAV 下载失败');
    return response.bodyBytes;
  }

  @override
  Future<ObjectMeta?> head(String path) async {
    final headResponse = await _guardRequest(
      () async {
        final request = http.Request('HEAD', _buildUri(path))
          ..headers.addAll(_headers());
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
      errorPrefix: 'WebDAV HEAD 失败',
    );

    if (headResponse.statusCode == 404) {
      return null;
    }
    if (headResponse.statusCode >= 200 && headResponse.statusCode < 300) {
      return _metaFromHeaders(headResponse.headers, headResponse.contentLength);
    }

    if (headResponse.statusCode == 405 ||
        headResponse.statusCode == 501 ||
        headResponse.statusCode == 400) {
      final propfind = await _tryPropfind(path);
      if (propfind != null) {
        return propfind;
      }
      return _headViaGet(path);
    }

    _ensureSuccess(headResponse, defaultMessage: 'WebDAV HEAD 失败');
    return _metaFromHeaders(headResponse.headers, headResponse.contentLength);
  }

  Future<ObjectMeta?> _tryPropfind(String path) async {
    final response = await _guardRequest(
      () async {
        final request = http.Request('PROPFIND', _buildUri(path))
          ..headers.addAll({
            ..._headers(),
            'Depth': '0',
            'Content-Type': 'application/xml',
          })
          ..body =
              '<?xml version="1.0" encoding="utf-8"?>'
              '<d:propfind xmlns:d="DAV:">'
              '<d:prop><d:getetag/><d:getlastmodified/><d:getcontentlength/></d:prop>'
              '</d:propfind>';
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
      errorPrefix: 'WebDAV PROPFIND 失败',
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 207 &&
        !(response.statusCode >= 200 && response.statusCode < 300)) {
      return null;
    }
    return _metaFromPropfind(response.body) ??
        _metaFromHeaders(response.headers, response.contentLength);
  }

  Future<ObjectMeta?> _headViaGet(String path) async {
    final response = await _guardRequest(
      () => _client.get(_buildUri(path), headers: _headers()),
      errorPrefix: 'WebDAV 读取元数据失败',
    );
    if (response.statusCode == 404 ||
        response.statusCode == 405 ||
        response.statusCode == 409) {
      return null;
    }
    _ensureSuccess(response, defaultMessage: 'WebDAV 读取元数据失败');
    return _metaFromHeaders(response.headers, response.bodyBytes.length);
  }

  @override
  Future<void> delete(String path) async {
    final response = await _guardRequest(
      () async {
        final request = http.Request('DELETE', _buildUri(path))
          ..headers.addAll(_headers());
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
      errorPrefix: 'WebDAV 删除失败',
    );
    if (response.statusCode == 404) {
      return;
    }
    _ensureSuccess(response, defaultMessage: 'WebDAV 删除失败');
  }

  Uri _buildUri(String path) {
    final baseUri = Uri.parse(config.serverUrl.trim());
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final remotePath = path.startsWith('/') ? path : '/$path';
    return baseUri.replace(path: '$basePath$remotePath');
  }

  Map<String, String> _headers({String? contentType}) {
    final auth = base64Encode(
      utf8.encode('${config.username}:${config.password}'),
    );
    return {
      'Authorization': 'Basic $auth',
      'Accept': '*/*',
      if (contentType != null) 'Content-Type': contentType,
    };
  }

  Future<void> _ensureParentDirectories(String path) async {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final segments = normalized
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.length <= 1) {
      return;
    }
    final baseUri = Uri.parse(config.serverUrl.trim());
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    var currentPath = basePath;
    for (final segment in segments.take(segments.length - 1)) {
      currentPath = '$currentPath/$segment';
      final dirUri = baseUri.replace(path: currentPath);
      // 坚果云等对已存在目录再 MKCOL 可能很慢或异常；先探测再创建。
      if (await _collectionExists(dirUri)) {
        continue;
      }
      await _mkcol(dirUri);
    }
  }

  Future<bool> _collectionExists(Uri dirUri) async {
    try {
      final propfind = await _guardRequest(
        () async {
          final request = http.Request('PROPFIND', dirUri)
            ..headers.addAll({
              ..._headers(),
              'Depth': '0',
              'Content-Type': 'application/xml',
            })
            ..body =
                '<?xml version="1.0" encoding="utf-8"?>'
                '<d:propfind xmlns:d="DAV:">'
                '<d:prop><d:resourcetype/></d:prop>'
                '</d:propfind>';
          final streamed = await _client.send(request);
          return http.Response.fromStream(streamed);
        },
        errorPrefix: 'WebDAV 检查目录失败',
      );
      if (propfind.statusCode == 207 ||
          (propfind.statusCode >= 200 && propfind.statusCode < 300)) {
        return true;
      }
      if (propfind.statusCode == 404) {
        return false;
      }
    } on CloudSyncException {
      // 探测失败时回退 MKCOL
    }

    try {
      final get = await _guardRequest(
        () => _client.get(dirUri, headers: _headers()),
        errorPrefix: 'WebDAV 检查目录失败',
      );
      return get.statusCode >= 200 && get.statusCode < 300;
    } on CloudSyncException {
      return false;
    }
  }

  Future<void> _mkcol(Uri dirUri) async {
    late final http.Response response;
    try {
      response = await _guardRequest(
        () async {
          final request = http.Request('MKCOL', dirUri)
            ..headers.addAll(_headers());
          final streamed = await _client.send(request);
          return http.Response.fromStream(streamed);
        },
        errorPrefix: '创建 WebDAV 目录失败',
      );
    } on CloudSyncException {
      // 超时或网络抖动：若目录实际已存在则视为成功（恢复/加锁常见）。
      if (await _collectionExists(dirUri)) {
        return;
      }
      rethrow;
    }
    if (response.statusCode == 201 ||
        response.statusCode == 200 ||
        response.statusCode == 405 ||
        response.statusCode == 301 ||
        response.statusCode == 302 ||
        response.statusCode == 409) {
      return;
    }
    // 已存在时部分服务仍返回其它状态码；再确认一次。
    if (await _collectionExists(dirUri)) {
      return;
    }
    _ensureSuccess(response, defaultMessage: '创建 WebDAV 目录失败');
  }

  ObjectMeta _metaFromHeaders(Map<String, String> headers, int? contentLength) {
    final etag = headers['etag'] ?? headers['ETag'];
    final lastModifiedRaw =
        headers['last-modified'] ?? headers['Last-Modified'];
    DateTime? lastModified;
    if (lastModifiedRaw != null && lastModifiedRaw.isNotEmpty) {
      lastModified = DateTime.tryParse(lastModifiedRaw)?.toUtc();
      // HTTP-date 常见格式：Wed, 21 Oct 2015 07:28:00 GMT
      lastModified ??= _tryParseHttpDate(lastModifiedRaw);
    }
    final lengthHeader = headers['content-length'] ?? headers['Content-Length'];
    final parsedLength = lengthHeader == null
        ? contentLength
        : int.tryParse(lengthHeader) ?? contentLength;
    return ObjectMeta(
      etag: etag,
      lastModified: lastModified,
      contentLength: parsedLength,
    );
  }

  ObjectMeta? _metaFromPropfind(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    final etag = _xmlTag(body, 'getetag');
    final lastModifiedRaw = _xmlTag(body, 'getlastmodified');
    final lengthRaw = _xmlTag(body, 'getcontentlength');
    if (etag == null && lastModifiedRaw == null && lengthRaw == null) {
      return null;
    }
    return ObjectMeta(
      etag: etag,
      lastModified: lastModifiedRaw == null
          ? null
          : (DateTime.tryParse(lastModifiedRaw)?.toUtc() ??
                _tryParseHttpDate(lastModifiedRaw)),
      contentLength: lengthRaw == null ? null : int.tryParse(lengthRaw),
    );
  }

  String? _xmlTag(String body, String localName) {
    final pattern = RegExp(
      '<[^:>]*:?$localName[^>]*>([^<]*)</[^:>]*:?$localName>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(body);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  DateTime? _tryParseHttpDate(String raw) {
    // 宽松解析常见 RFC1123；失败则返回 null。
    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final match = RegExp(
      r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    final month = months[match.group(2)!];
    if (month == null) {
      return null;
    }
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  bool _looksLikeUnsupportedPrecondition(int statusCode) {
    return statusCode == 400 ||
        statusCode == 405 ||
        statusCode == 501 ||
        statusCode == 422;
  }

  Future<http.Response> _guardRequest(
    Future<http.Response> Function() request, {
    required String errorPrefix,
  }) async {
    try {
      return await request().timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw CloudSyncException('$errorPrefix：网络连接异常（${e.message}）');
    } on FormatException {
      throw CloudSyncException('$errorPrefix：服务地址格式错误');
    } on CloudSyncException {
      rethrow;
    } catch (_) {
      throw CloudSyncException('$errorPrefix：请求超时或网络异常');
    }
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
      message = '$defaultMessage：认证失败，请检查用户名或密码';
    } else if (code == 404) {
      message = '$defaultMessage：远端文件不存在';
    } else if (code == 409) {
      message = '$defaultMessage：远端路径冲突，请检查上级目录是否可写';
    } else if (code >= 500) {
      message = '$defaultMessage：服务器异常（$code）';
    } else {
      message = '$defaultMessage：HTTP $code';
    }
    throw CloudSyncException(message, statusCode: code);
  }
}
