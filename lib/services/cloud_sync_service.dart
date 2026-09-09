import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wangcai_core/wangcai_core.dart';

/// App 侧云同步适配：配置持久化 + 基于 [SyncClient] 的加锁推送/拉取。
class CloudSyncService {
  static const _protocolKey = 'cloud_sync_protocol';
  static const _lastBackupAtKey = 'cloud_sync_last_backup_at';
  static const _deviceIdKey = 'cloud_sync_device_id';
  static const _localRevisionKey = 'cloud_sync_local_revision';

  static const _legacyLastBackupAtKey = 'webdav_last_backup_at';
  static const _legacyDeviceIdKey = 'webdav_device_id';

  static const _webdavServerUrlKey = 'webdav_server_url';
  static const _webdavUsernameKey = 'webdav_username';
  static const _webdavPasswordKey = 'webdav_password';
  static const _webdavRemotePathKey = 'webdav_remote_path';

  static const _s3EndpointKey = 's3_endpoint';
  static const _s3RegionKey = 's3_region';
  static const _s3BucketKey = 's3_bucket';
  static const _s3ObjectKeyKey = 's3_object_key';
  static const _s3AccessKeyIdKey = 's3_access_key_id';
  static const _s3SecretKey = 's3_secret_access_key';
  static const _s3ForcePathStyleKey = 's3_force_path_style';

  static const _secureStorage = FlutterSecureStorage();

  /// 浏览器受 CORS 限制，无法直连坚果云等第三方 WebDAV/S3。
  static bool get isSupportedOnCurrentPlatform => !kIsWeb;

  static const unsupportedPlatformMessage =
      '当前为浏览器（Web）环境，受 CORS 限制无法直连坚果云等 WebDAV/S3。'
      '请使用 Android / iOS / 桌面版 App，或本机 wangcai CLI。';

  static void _ensurePlatformSupported() {
    if (!isSupportedOnCurrentPlatform) {
      throw const CloudSyncException(
        unsupportedPlatformMessage,
        code: 'UNSUPPORTED_PLATFORM',
      );
    }
  }

  static Future<void> saveConfig(CloudSyncConfig config) async {
    if (!config.isValid) {
      throw const CloudSyncException('云备份配置不完整');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_protocolKey, config.protocol.name);

    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        final webdav = config.webdav!;
        await prefs.setString(_webdavServerUrlKey, webdav.serverUrl.trim());
        await prefs.setString(_webdavUsernameKey, webdav.username.trim());
        await prefs.setString(_webdavRemotePathKey, webdav.folderPath);
        await _secureStorage.write(
          key: _webdavPasswordKey,
          value: webdav.password,
        );
        await prefs.remove(_webdavPasswordKey);
        break;
      case CloudSyncProtocol.s3:
        final s3 = config.s3!;
        await prefs.setString(_s3EndpointKey, s3.endpoint.trim());
        await prefs.setString(_s3RegionKey, s3.region.trim());
        await prefs.setString(_s3BucketKey, s3.bucket.trim());
        await prefs.setString(_s3ObjectKeyKey, s3.folderKey);
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
    final webdav = await _loadWebDavConfig(prefs);
    final s3 = await _loadS3Config(prefs);

    switch (protocol) {
      case CloudSyncProtocol.webdav:
        if (webdav != null) {
          return CloudSyncConfig(
            protocol: CloudSyncProtocol.webdav,
            webdav: webdav,
          );
        }
        if (s3 != null) {
          return CloudSyncConfig(protocol: CloudSyncProtocol.s3, s3: s3);
        }
        return null;
      case CloudSyncProtocol.s3:
        if (s3 != null) {
          return CloudSyncConfig(protocol: CloudSyncProtocol.s3, s3: s3);
        }
        if (webdav != null) {
          return CloudSyncConfig(
            protocol: CloudSyncProtocol.webdav,
            webdav: webdav,
          );
        }
        return null;
    }
  }

  static Future<({WebDavBackupConfig? webdav, S3BackupConfig? s3})>
      loadDraftConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      webdav: await _loadWebDavConfig(prefs),
      s3: await _loadS3Config(prefs),
    );
  }

  static Future<WebDavBackupConfig?> _loadWebDavConfig(
    SharedPreferences prefs,
  ) async {
    final serverUrl = prefs.getString(_webdavServerUrlKey) ?? '';
    final username = prefs.getString(_webdavUsernameKey) ?? '';
    var password = await _secureStorage.read(key: _webdavPasswordKey) ?? '';
    if (password.isEmpty) {
      final legacy = prefs.getString(_webdavPasswordKey) ?? '';
      if (legacy.isNotEmpty) {
        await _secureStorage.write(key: _webdavPasswordKey, value: legacy);
        await prefs.remove(_webdavPasswordKey);
        password = legacy;
      }
    }
    final remotePath = prefs.getString(_webdavRemotePathKey) ?? '';
    final config = WebDavBackupConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
      remotePath: remotePath,
    );
    return config.isValid ? config : null;
  }

  static Future<S3BackupConfig?> _loadS3Config(SharedPreferences prefs) async {
    final config = S3BackupConfig(
      endpoint: prefs.getString(_s3EndpointKey) ?? '',
      region: prefs.getString(_s3RegionKey) ?? 'us-east-1',
      bucket: prefs.getString(_s3BucketKey) ?? '',
      objectKey: prefs.getString(_s3ObjectKeyKey) ?? 'wangcai',
      accessKeyId: prefs.getString(_s3AccessKeyIdKey) ?? '',
      secretAccessKey: await _secureStorage.read(key: _s3SecretKey) ?? '',
      forcePathStyle: prefs.getBool(_s3ForcePathStyleKey) ?? true,
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

  static Future<int> getLocalRevision() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localRevisionKey) ?? 0;
  }

  static Future<void> setLocalRevision(int revision) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localRevisionKey, revision);
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
    final now = DateTime.now().microsecondsSinceEpoch;
    final deviceId =
        'wc_${now.toRadixString(36)}_${(now % 1000000).toRadixString(36)}';
    await prefs.setString(_deviceIdKey, deviceId);
    await prefs.setString(_legacyDeviceIdKey, deviceId);
    return deviceId;
  }

  static Future<SyncClient> createSyncClient(CloudSyncConfig config) async {
    _ensurePlatformSupported();
    if (!config.isValid) {
      throw const CloudSyncException('云备份配置不完整');
    }
    final ownerId = await getOrCreateDeviceId();
    final ObjectStore store;
    switch (config.protocol) {
      case CloudSyncProtocol.webdav:
        store = WebDavObjectStore(config.webdav!);
        break;
      case CloudSyncProtocol.s3:
        store = S3ObjectStore(config.s3!);
        break;
    }
    return SyncClient(
      store: store,
      ownerId: ownerId,
      ledgerPath: config.ledgerPath,
      revisionPath: config.revisionPath,
      lockPath: config.lockPath,
    );
  }

  /// 持锁推送本地账本；远端更新时需 [force]=true。
  static Future<LedgerBundle> uploadBackup(
    CloudSyncConfig config,
    LedgerBundle bundle, {
    bool force = false,
  }) async {
    final client = await createSyncClient(config);
    final localRevision = await getLocalRevision();
    final ledger = Ledger(
      bundle.copyWith(
        revision: bundle.revision > localRevision
            ? bundle.revision
            : localRevision,
        deviceId: await getOrCreateDeviceId(),
        schemaVersion: LedgerBundle.currentSchemaVersion,
      ),
    );
    // 构造 Ledger 时 replaceAll 已重算；上传前再确保自洽（显式调用便于语义清晰）。
    ledger.ensureOpeningBalances();
    ledger.recomputeBalancesFromTransactions();
    final uploaded = await client.pushLocal(ledger, force: force);
    await setLocalRevision(uploaded.revision);
    await markSyncNow();
    return uploaded;
  }

  /// 持锁从远端恢复。
  static Future<LedgerBundle> downloadBackup(CloudSyncConfig config) async {
    final client = await createSyncClient(config);
    final ledger = Ledger();
    final bundle = await client.pullReplace(ledger);
    await setLocalRevision(bundle.revision);
    await markSyncNow();
    return bundle;
  }

  /// 读活（不加锁），用于覆盖前提示。
  static Future<LedgerBundle?> fetchRemoteBundleMeta(
    CloudSyncConfig config,
  ) async {
    final client = await createSyncClient(config);
    return client.downloadBundle();
  }

  /// 读操作：远端 revision 更新则返回远端 bundle，否则 null。
  static Future<LedgerBundle?> ensureFreshIfNeeded(
    CloudSyncConfig config,
  ) async {
    final client = await createSyncClient(config);
    final localRevision = await getLocalRevision();
    final remoteRevision = await client.fetchRemoteRevision();
    if (remoteRevision == null || remoteRevision <= localRevision) {
      return null;
    }
    final remote = await client.downloadBundle();
    if (remote == null) {
      return null;
    }
    final withRevision = remote.revision >= remoteRevision
        ? remote
        : remote.copyWith(revision: remoteRevision);
    // 与 pullReplace / Ledger.replaceAll 一致：补齐期初并按流水重算余额。
    return Ledger(withRevision).toBundle();
  }
}

typedef WebDavServiceException = CloudSyncException;
