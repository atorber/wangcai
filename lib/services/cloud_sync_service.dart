import 'dart:math';

import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/cloud_sync_config.dart';
import 'package:finance_app/models/webdav_backup_config.dart';
import 'package:finance_app/services/cloud_sync_exception.dart';
import 'package:finance_app/services/s3_backup_service.dart';
import 'package:finance_app/services/webdav_backup_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 统一云备份门面：WebDAV / S3 共用同一份 [AppBackupBundle]。
class CloudSyncService {
  static const _protocolKey = 'cloud_sync_protocol';
  static const _lastBackupAtKey = 'cloud_sync_last_backup_at';
  static const _deviceIdKey = 'cloud_sync_device_id';

  static const _legacyLastBackupAtKey = 'webdav_last_backup_at';
  static const _legacyDeviceIdKey = 'webdav_device_id';

  static const _s3EndpointKey = 's3_endpoint';
  static const _s3RegionKey = 's3_region';
  static const _s3BucketKey = 's3_bucket';
  static const _s3ObjectKeyKey = 's3_object_key';
  static const _s3AccessKeyIdKey = 's3_access_key_id';
  static const _s3SecretKey = 's3_secret_access_key';
  static const _s3ForcePathStyleKey = 's3_force_path_style';

  static const _secureStorage = FlutterSecureStorage();

  static Future<void> saveConfig(CloudSyncConfig config) async {
    if (!config.isValid) {
      throw const CloudSyncException('云备份配置不完整');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_protocolKey, config.protocol.name);

    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        await WebDavBackupService.saveConfig(config.webdav!);
        break;
      case CloudSyncProtocol.s3:
        final s3 = config.s3!;
        await prefs.setString(_s3EndpointKey, s3.endpoint.trim());
        await prefs.setString(_s3RegionKey, s3.region.trim());
        await prefs.setString(_s3BucketKey, s3.bucket.trim());
        await prefs.setString(_s3ObjectKeyKey, s3.objectKey.trim());
        await prefs.setString(_s3AccessKeyIdKey, s3.accessKeyId.trim());
        await prefs.setBool(_s3ForcePathStyleKey, s3.forcePathStyle);
        await _secureStorage.write(
          key: _s3SecretKey,
          value: s3.secretAccessKey.trim(),
        );
        break;
    }
  }

  static Future<CloudSyncConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final protocol = cloudSyncProtocolFromName(prefs.getString(_protocolKey));

    switch (protocol) {
      case CloudSyncProtocol.webdav:
        final webdav = await WebDavBackupService.loadConfig();
        if (webdav == null) {
          // 未显式选协议时，若仅有 S3 配置也可回退
          final s3 = await _loadS3Config(prefs);
          if (s3 != null) {
            return CloudSyncConfig(protocol: CloudSyncProtocol.s3, s3: s3);
          }
          return null;
        }
        return CloudSyncConfig(
          protocol: CloudSyncProtocol.webdav,
          webdav: webdav,
        );
      case CloudSyncProtocol.s3:
        final s3 = await _loadS3Config(prefs);
        if (s3 == null) {
          final webdav = await WebDavBackupService.loadConfig();
          if (webdav != null) {
            return CloudSyncConfig(
              protocol: CloudSyncProtocol.webdav,
              webdav: webdav,
            );
          }
          return null;
        }
        return CloudSyncConfig(protocol: CloudSyncProtocol.s3, s3: s3);
    }
  }

  /// 读取已保存的 WebDAV / S3 草稿（不论当前协议），供配置页切换预填。
  static Future<({WebDavBackupConfig? webdav, S3BackupConfig? s3})>
      loadDraftConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      webdav: await WebDavBackupService.loadConfig(),
      s3: await _loadS3Config(prefs),
    );
  }

  static Future<S3BackupConfig?> _loadS3Config(SharedPreferences prefs) async {
    final endpoint = prefs.getString(_s3EndpointKey) ?? '';
    final region = prefs.getString(_s3RegionKey) ?? 'us-east-1';
    final bucket = prefs.getString(_s3BucketKey) ?? '';
    final objectKey = prefs.getString(_s3ObjectKeyKey) ?? 'wangcai/records.json';
    final accessKeyId = prefs.getString(_s3AccessKeyIdKey) ?? '';
    final secret =
        await _secureStorage.read(key: _s3SecretKey) ?? '';
    final forcePathStyle = prefs.getBool(_s3ForcePathStyleKey) ?? true;
    final config = S3BackupConfig(
      endpoint: endpoint,
      region: region,
      bucket: bucket,
      objectKey: objectKey,
      accessKeyId: accessKeyId,
      secretAccessKey: secret,
      forcePathStyle: forcePathStyle,
    );
    return config.isValid ? config : null;
  }

  static Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_lastBackupAtKey);
    if (current != null && current.isNotEmpty) {
      return current;
    }
    final legacy = prefs.getString(_legacyLastBackupAtKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_lastBackupAtKey, legacy);
      return legacy;
    }
    return null;
  }

  static Future<void> markSyncNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_lastBackupAtKey, now);
    await prefs.setString(_legacyLastBackupAtKey, now);
  }

  static Future<void> uploadBackup(
    CloudSyncConfig config,
    AppBackupBundle bundle,
  ) async {
    final enriched = await _enrichBundle(bundle);
    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        await WebDavBackupService.uploadBackup(config.webdav!, enriched);
        break;
      case CloudSyncProtocol.s3:
        await S3BackupService.uploadBackup(config.s3!, enriched);
        break;
    }
    await markSyncNow();
  }

  static Future<AppBackupBundle> downloadBackup(CloudSyncConfig config) async {
    final AppBackupBundle bundle;
    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        bundle = await WebDavBackupService.downloadBackup(config.webdav!);
        break;
      case CloudSyncProtocol.s3:
        bundle = await S3BackupService.downloadBackup(config.s3!);
        break;
    }
    await markSyncNow();
    return bundle;
  }

  static Future<AppBackupBundle?> fetchRemoteBundleMeta(
    CloudSyncConfig config,
  ) async {
    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        return WebDavBackupService.fetchRemoteBundleMeta(config.webdav!);
      case CloudSyncProtocol.s3:
        return S3BackupService.fetchRemoteBundleMeta(config.s3!);
    }
  }

  static Future<AppBackupBundle> _enrichBundle(AppBackupBundle bundle) async {
    return AppBackupBundle(
      version: bundle.version,
      schemaVersion: bundle.schemaVersion,
      deviceId: await getOrCreateDeviceId(),
      exportedAt: bundle.exportedAt,
      accounts: bundle.accounts,
      lenders: bundle.lenders,
      categories: bundle.categories,
      transactions: bundle.transactions,
    );
  }

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final legacy = prefs.getString(_legacyDeviceIdKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_deviceIdKey, legacy);
      return legacy;
    }
    final random = Random();
    final now = DateTime.now().microsecondsSinceEpoch;
    final deviceId =
        'wc_${now.toRadixString(36)}_${random.nextInt(1 << 20).toRadixString(36)}';
    await prefs.setString(_deviceIdKey, deviceId);
    await prefs.setString(_legacyDeviceIdKey, deviceId);
    return deviceId;
  }
}
