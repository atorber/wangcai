import 'dart:convert';

import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/github_sync_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GithubSyncService {
  static const _tokenKey = 'github_token';
  static const _ownerKey = 'github_owner';
  static const _repoKey = 'github_repo';
  static const _pathKey = 'github_path';
  static const _branchKey = 'github_branch';
  static const _lastSyncAtKey = 'github_last_sync_at';

  static Future<void> saveConfig(GithubSyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, config.token);
    await prefs.setString(_ownerKey, config.owner);
    await prefs.setString(_repoKey, config.repo);
    await prefs.setString(_pathKey, config.path);
    await prefs.setString(_branchKey, config.branch);
  }

  static Future<GithubSyncConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';
    final owner = prefs.getString(_ownerKey) ?? '';
    final repo = prefs.getString(_repoKey) ?? '';
    final path = prefs.getString(_pathKey) ?? '';
    final branch = prefs.getString(_branchKey) ?? 'main';
    final config = GithubSyncConfig(
      token: token,
      owner: owner,
      repo: repo,
      path: path,
      branch: branch,
    );
    return config.isValid ? config : null;
  }

  static Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncAtKey);
  }

  static Future<void> markSyncNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncAtKey, DateTime.now().toIso8601String());
  }

  static Future<void> uploadBackup(
    GithubSyncConfig config,
    AppBackupBundle bundle,
  ) async {
    final payload = jsonEncode(bundle.toJson());
    final encodedContent = base64Encode(utf8.encode(payload));
    final existing = await _getFile(config, throwIfMissing: false);
    final body = {
      'message': 'sync wangcai records',
      'content': encodedContent,
      'branch': config.branch,
      if (existing != null && existing['sha'] != null) 'sha': existing['sha'],
    };

    final response = await http.put(
      _buildFileUri(config),
      headers: _headers(config.token),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('上传失败: ${response.statusCode} ${response.body}');
    }
    await markSyncNow();
  }

  static Future<AppBackupBundle> downloadBackup(
    GithubSyncConfig config,
  ) async {
    final jsonMap = await _getFile(config, throwIfMissing: true);
    final content = jsonMap?['content'] as String? ?? '';
    final normalized = content.replaceAll('\n', '');
    final decoded = utf8.decode(base64Decode(normalized));
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    final bundle = AppBackupBundle.fromJson(data);
    await markSyncNow();
    return bundle;
  }

  static Future<Map<String, dynamic>?> _getFile(
    GithubSyncConfig config, {
    required bool throwIfMissing,
  }) async {
    final response = await http.get(
      _buildFileUri(config),
      headers: _headers(config.token),
    );
    if (response.statusCode == 404 && !throwIfMissing) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('读取远端文件失败: ${response.statusCode} ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Uri _buildFileUri(GithubSyncConfig config) {
    return Uri.https(
      'api.github.com',
      '/repos/${config.owner}/${config.repo}/contents/${config.path}',
      {'ref': config.branch},
    );
  }

  static Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
      'Content-Type': 'application/json',
    };
  }
}
