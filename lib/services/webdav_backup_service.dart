import 'dart:convert';

import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/webdav_backup_config.dart';
import 'package:finance_app/services/cloud_sync_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef WebDavServiceException = CloudSyncException;

class WebDavBackupService {
  static const _serverUrlKey = 'webdav_server_url';
  static const _usernameKey = 'webdav_username';
  static const _passwordKey = 'webdav_password';
  static const _remotePathKey = 'webdav_remote_path';
  static const _requestTimeout = Duration(seconds: 15);
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> saveConfig(WebDavBackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, config.serverUrl);
    await prefs.setString(_usernameKey, config.username);
    await _secureStorage.write(key: _passwordKey, value: config.password);
    await prefs.remove(_passwordKey);
    await prefs.setString(_remotePathKey, config.remotePath);
  }

  static Future<WebDavBackupConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_serverUrlKey) ?? '';
    final username = prefs.getString(_usernameKey) ?? '';
    var password = await _secureStorage.read(key: _passwordKey) ?? '';
    if (password.isEmpty) {
      final legacyPassword = prefs.getString(_passwordKey) ?? '';
      if (legacyPassword.isNotEmpty) {
        await _secureStorage.write(key: _passwordKey, value: legacyPassword);
        await prefs.remove(_passwordKey);
        password = legacyPassword;
      }
    }
    final remotePath = prefs.getString(_remotePathKey) ?? '';
    final config = WebDavBackupConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      remotePath: remotePath,
    );
    return config.isValid ? config : null;
  }

  static Future<void> uploadBackup(
    WebDavBackupConfig config,
    AppBackupBundle bundle,
  ) async {
    await _ensureRemoteDirectoryExists(config);
    final payload = jsonEncode(bundle.toJson());
    final response = await _guardRequest(
      () => http.put(
        _buildFileUri(config),
        headers: _headers(config),
        body: payload,
      ),
      errorPrefix: 'WebDAV 备份失败',
    );
    _ensureSuccess(response, defaultMessage: 'WebDAV 备份失败');
  }

  static Future<AppBackupBundle> downloadBackup(
    WebDavBackupConfig config,
  ) async {
    final response = await _guardRequest(
      () => http.get(
        _buildFileUri(config),
        headers: _headers(config),
      ),
      errorPrefix: 'WebDAV 下载失败',
    );
    _ensureSuccess(response, defaultMessage: 'WebDAV 下载失败');
    if (response.body.trim().isEmpty) {
      throw const CloudSyncException('WebDAV 文件为空，无法恢复');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const CloudSyncException('WebDAV 文件格式错误，无法解析 JSON');
    }
    if (decoded is! Map) {
      throw const CloudSyncException('WebDAV 文件结构无效，无法恢复');
    }
    return AppBackupBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<AppBackupBundle?> fetchRemoteBundleMeta(
    WebDavBackupConfig config,
  ) async {
    final response = await _guardRequest(
      () => http.get(
        _buildFileUri(config),
        headers: _headers(config),
      ),
      errorPrefix: '读取远端备份信息失败',
    );
    if (response.statusCode == 404 ||
        response.statusCode == 405 ||
        response.statusCode == 409) {
      return null;
    }
    _ensureSuccess(response, defaultMessage: '读取远端备份信息失败');
    if (response.body.trim().isEmpty) {
      return null;
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    return AppBackupBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<void> _ensureRemoteDirectoryExists(
    WebDavBackupConfig config,
  ) async {
    final remotePath = config.remotePath.startsWith('/')
        ? config.remotePath.substring(1)
        : config.remotePath;
    final segments = remotePath
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.length <= 1) {
      return;
    }
    final baseUri = Uri.parse(config.serverUrl);
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    var currentPath = basePath;
    for (final segment in segments.take(segments.length - 1)) {
      currentPath = '$currentPath/$segment';
      final dirUri = baseUri.replace(path: currentPath);
      await _mkcol(config, dirUri);
    }
  }

  static Future<void> _mkcol(WebDavBackupConfig config, Uri dirUri) async {
    final response = await _guardRequest(
      () async {
        final client = http.Client();
        try {
          final request = http.Request('MKCOL', dirUri)
            ..headers.addAll(_headers(config));
          final streamed = await client.send(request);
          return http.Response.fromStream(streamed);
        } finally {
          client.close();
        }
      },
      errorPrefix: '创建 WebDAV 目录失败',
    );
    if (response.statusCode == 201 || response.statusCode == 405) {
      return;
    }
    _ensureSuccess(response, defaultMessage: '创建 WebDAV 目录失败');
  }

  static Uri _buildFileUri(WebDavBackupConfig config) {
    final baseUri = Uri.parse(config.serverUrl);
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final remotePath = config.remotePath.startsWith('/')
        ? config.remotePath
        : '/${config.remotePath}';
    return baseUri.replace(path: '$basePath$remotePath');
  }

  static Map<String, String> _headers(WebDavBackupConfig config) {
    final auth = base64Encode(
      utf8.encode('${config.username}:${config.password}'),
    );
    return {
      'Authorization': 'Basic $auth',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> _guardRequest(
    Future<http.Response> Function() request, {
    required String errorPrefix,
  }) async {
    try {
      return await request().timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw CloudSyncException('$errorPrefix：网络连接异常（${e.message}）');
    } on FormatException {
      throw CloudSyncException('$errorPrefix：服务地址格式错误');
    } catch (_) {
      throw CloudSyncException('$errorPrefix：请求超时或网络异常');
    }
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
      message = '$defaultMessage：认证失败，请检查用户名或密码';
    } else if (code == 404) {
      message = '$defaultMessage：远端文件不存在，请先执行备份';
    } else if (code == 409) {
      message = '$defaultMessage：远端路径冲突，请检查备份路径的上级目录是否可写';
    } else if (code >= 500) {
      message = '$defaultMessage：服务器异常（$code）';
    } else {
      message = '$defaultMessage：HTTP $code';
    }
    throw CloudSyncException(message, statusCode: code);
  }
}
