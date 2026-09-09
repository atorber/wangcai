enum CloudSyncProtocol { webdav, s3 }

CloudSyncProtocol cloudSyncProtocolFromName(String? name) {
  switch (name) {
    case 's3':
      return CloudSyncProtocol.s3;
    default:
      return CloudSyncProtocol.webdav;
  }
}

/// 旺财远端账本目录布局（用户只配置文件夹，文件名由应用固定）。
class CloudLedgerLayout {
  static const String ledgerFileName = 'records.json';
  static const String revisionFileName = 'revision.json';
  static const String lockFileName = 'lock.json';

  /// WebDAV：规范化为以 `/` 开头、无尾 `/` 的目录，例如 `/wangcai`。
  /// 兼容旧配置：若传入文件路径（如 `/wangcai/records.json`）则取父目录。
  static String normalizeWebDavFolder(String raw) {
    var path = raw.trim();
    if (path.isEmpty) {
      return '/wangcai';
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    while (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (_looksLikeFilePath(path)) {
      final idx = path.lastIndexOf('/');
      path = idx <= 0 ? '/wangcai' : path.substring(0, idx);
    }
    return path.isEmpty ? '/wangcai' : path;
  }

  /// S3：规范化为无前导 `/`、无尾 `/` 的前缀，例如 `wangcai`。
  static String normalizeS3Folder(String raw) {
    var key = raw.trim();
    while (key.startsWith('/')) {
      key = key.substring(1);
    }
    while (key.endsWith('/')) {
      key = key.substring(0, key.length - 1);
    }
    if (_looksLikeFilePath(key)) {
      final idx = key.lastIndexOf('/');
      key = idx < 0 ? 'wangcai' : key.substring(0, idx);
    }
    return key.isEmpty ? 'wangcai' : key;
  }

  static bool _looksLikeFilePath(String path) {
    final name = path.split('/').last.toLowerCase();
    return name.endsWith('.json') || name.endsWith('.lock');
  }

  static String joinWebDav(String folder, String fileName) {
    final base = normalizeWebDavFolder(folder);
    return '$base/$fileName';
  }

  static String joinS3(String folder, String fileName) {
    final base = normalizeS3Folder(folder);
    return '$base/$fileName';
  }
}

class WebDavBackupConfig {
  const WebDavBackupConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.remotePath,
  });

  final String serverUrl;
  final String username;
  final String password;

  /// 远端账本**目录**（非文件）。兼容旧值 `/wangcai/records.json`（自动取父目录）。
  final String remotePath;

  bool get isValid =>
      serverUrl.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.trim().isNotEmpty &&
      remotePath.trim().isNotEmpty;

  String get folderPath => CloudLedgerLayout.normalizeWebDavFolder(remotePath);

  String get ledgerRemotePath =>
      CloudLedgerLayout.joinWebDav(folderPath, CloudLedgerLayout.ledgerFileName);

  String get revisionRemotePath => CloudLedgerLayout.joinWebDav(
    folderPath,
    CloudLedgerLayout.revisionFileName,
  );

  String get lockRemotePath =>
      CloudLedgerLayout.joinWebDav(folderPath, CloudLedgerLayout.lockFileName);
}

class S3BackupConfig {
  const S3BackupConfig({
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.objectKey,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.forcePathStyle = true,
  });

  final String endpoint;
  final String region;
  final String bucket;

  /// 远端账本**目录前缀**（非文件）。兼容旧值 `wangcai/records.json`。
  final String objectKey;
  final String accessKeyId;
  final String secretAccessKey;
  final bool forcePathStyle;

  bool get isValid =>
      endpoint.trim().isNotEmpty &&
      region.trim().isNotEmpty &&
      bucket.trim().isNotEmpty &&
      objectKey.trim().isNotEmpty &&
      accessKeyId.trim().isNotEmpty &&
      secretAccessKey.trim().isNotEmpty;

  String get folderKey => CloudLedgerLayout.normalizeS3Folder(objectKey);

  String get ledgerObjectKey =>
      CloudLedgerLayout.joinS3(folderKey, CloudLedgerLayout.ledgerFileName);

  String get revisionObjectKey =>
      CloudLedgerLayout.joinS3(folderKey, CloudLedgerLayout.revisionFileName);

  String get lockObjectKey =>
      CloudLedgerLayout.joinS3(folderKey, CloudLedgerLayout.lockFileName);
}

class CloudSyncConfig {
  const CloudSyncConfig({
    required this.protocol,
    this.webdav,
    this.s3,
  });

  final CloudSyncProtocol protocol;
  final WebDavBackupConfig? webdav;
  final S3BackupConfig? s3;

  bool get isValid {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.isValid ?? false;
      case CloudSyncProtocol.s3:
        return s3?.isValid ?? false;
    }
  }

  String get protocolLabel {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return 'WebDAV';
      case CloudSyncProtocol.s3:
        return 'S3';
    }
  }

  /// 用户配置的远端目录（规范化后）。
  String get folderPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.folderPath ?? '';
      case CloudSyncProtocol.s3:
        return s3?.folderKey ?? '';
    }
  }

  String get ledgerPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.ledgerRemotePath ?? '';
      case CloudSyncProtocol.s3:
        return s3?.ledgerObjectKey ?? '';
    }
  }

  String get revisionPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.revisionRemotePath ?? '';
      case CloudSyncProtocol.s3:
        return s3?.revisionObjectKey ?? '';
    }
  }

  String get lockPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.lockRemotePath ?? '';
      case CloudSyncProtocol.s3:
        return s3?.lockObjectKey ?? '';
    }
  }

  String get displayTarget {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.serverUrl ?? '--';
      case CloudSyncProtocol.s3:
        final config = s3;
        if (config == null) {
          return '--';
        }
        return '${config.bucket}/${config.folderKey}/';
    }
  }

  String get displayPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav == null ? '--' : '${webdav!.folderPath}/';
      case CloudSyncProtocol.s3:
        return s3?.endpoint ?? '--';
    }
  }
}
