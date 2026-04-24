import 'dart:convert';

import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/github_sync_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WebDavBackupService {
  static const _serverUrlKey = 'webdav_server_url';
  static const _usernameKey = 'webdav_username';
  static const _passwordKey = 'webdav_password';
  static const _remotePathKey = 'webdav_remote_path';
  static const _lastBackupAtKey = 'webdav_last_backup_at';

  static Future<void> saveConfig(WebDavBackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, config.serverUrl);
    await prefs.setString(_usernameKey, config.username);
    await prefs.setString(_passwordKey, config.password);
    await prefs.setString(_remotePathKey, config.remotePath);
  }

  static Future<WebDavBackupConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_serverUrlKey) ?? '';
    final username = prefs.getString(_usernameKey) ?? '';
    final password = prefs.getString(_passwordKey) ?? '';
    final remotePath = prefs.getString(_remotePathKey) ?? '';
    final config = WebDavBackupConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      remotePath: remotePath,
    );
    return config.isValid ? config : null;
  }

  static Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupAtKey);
  }

  static Future<void> markSyncNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAtKey, DateTime.now().toIso8601String());
  }

  static Future<void> uploadBackup(
    WebDavBackupConfig config,
    AppBackupBundle bundle,
  ) async {
    final payload = jsonEncode(bundle.toJson());
    final response = await http.put(
      _buildFileUri(config),
      headers: _headers(config),
      body: payload,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('WebDAV 备份失败: ${response.statusCode} ${response.body}');
    }
    await markSyncNow();
  }

  static Future<AppBackupBundle> downloadBackup(
    WebDavBackupConfig config,
  ) async {
    final response = await http.get(
      _buildFileUri(config),
      headers: _headers(config),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('WebDAV 下载失败: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bundle = AppBackupBundle.fromJson(data);
    await markSyncNow();
    return bundle;
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
    final auth = base64Encode(utf8.encode('${config.username}:${config.password}'));
    return {
      'Authorization': 'Basic $auth',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}
