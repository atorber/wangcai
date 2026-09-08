import 'package:finance_app/models/webdav_backup_config.dart';

enum CloudSyncProtocol { webdav, s3 }

CloudSyncProtocol cloudSyncProtocolFromName(String? name) {
  switch (name) {
    case 's3':
      return CloudSyncProtocol.s3;
    default:
      return CloudSyncProtocol.webdav;
  }
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

  String get displayTarget {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.serverUrl ?? '--';
      case CloudSyncProtocol.s3:
        final config = s3;
        if (config == null) {
          return '--';
        }
        return '${config.bucket}/${config.objectKey}';
    }
  }

  String get displayPath {
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return webdav?.remotePath ?? '--';
      case CloudSyncProtocol.s3:
        return s3?.endpoint ?? '--';
    }
  }
}
