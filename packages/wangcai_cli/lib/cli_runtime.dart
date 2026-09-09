import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:wangcai_core/wangcai_core.dart';

class CliRuntime {
  CliRuntime({
    required this.config,
    required this.client,
    required this.ledgerFile,
    required this.ledger,
  });

  final CloudSyncConfig config;
  final SyncClient client;
  final File ledgerFile;
  final Ledger ledger;

  static Future<CliRuntime> load({
    String? configPath,
    String? ledgerPath,
  }) async {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final root = p.join(home, '.wangcai');
    await Directory(root).create(recursive: true);

    final configFile = File(
      configPath ??
          Platform.environment['WANGCAI_CONFIG'] ??
          p.join(root, 'config.json'),
    );
    if (!await configFile.exists()) {
      throw const CloudSyncException(
        '未找到配置文件。请复制 config.example.json 到 ~/.wangcai/config.json',
        code: 'INVALID_PARAMS',
      );
    }
    final configJson =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final config = _parseConfig(configJson);
    if (!config.isValid) {
      throw const CloudSyncException('云同步配置不完整', code: 'INVALID_PARAMS');
    }

    final ownerId =
        (configJson['deviceId'] as String?)?.trim().isNotEmpty == true
        ? (configJson['deviceId'] as String).trim()
        : 'wc_cli_${Platform.localHostname}';

    final ObjectStore store = switch (config.protocol) {
      CloudSyncProtocol.webdav => WebDavObjectStore(config.webdav!),
      CloudSyncProtocol.s3 => S3ObjectStore(config.s3!),
    };
    final client = SyncClient(
      store: store,
      ownerId: ownerId,
      ledgerPath: config.ledgerPath,
      revisionPath: config.revisionPath,
      lockPath: config.lockPath,
    );

    final file = File(
      ledgerPath ??
          Platform.environment['WANGCAI_LEDGER'] ??
          p.join(root, 'ledger.json'),
    );
    final ledger = Ledger();
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        ledger.replaceAll(
          LedgerBundle.fromJson(Map<String, dynamic>.from(decoded)),
        );
      }
    }
    ledger.deviceId = ownerId;

    return CliRuntime(
      config: config,
      client: client,
      ledgerFile: file,
      ledger: ledger,
    );
  }

  Future<void> loadLocal() async {
    if (!await ledgerFile.exists()) {
      return;
    }
    final decoded = jsonDecode(await ledgerFile.readAsString());
    if (decoded is Map) {
      ledger.replaceAll(
        LedgerBundle.fromJson(Map<String, dynamic>.from(decoded)),
      );
    }
  }

  Future<void> saveLocal() async {
    await ledgerFile.parent.create(recursive: true);
    await ledgerFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(ledger.toBundle().toJson()),
    );
  }

  /// 读前对齐远端 revision。
  Future<void> ensureFreshRead() async {
    await loadLocal();
    await client.ensureFresh(ledger);
    await saveLocal();
  }

  static CloudSyncConfig _parseConfig(Map<String, dynamic> json) {
    final protocol = cloudSyncProtocolFromName(json['protocol'] as String?);
    switch (protocol) {
      case CloudSyncProtocol.webdav:
        return CloudSyncConfig(
          protocol: protocol,
          webdav: WebDavBackupConfig(
            serverUrl: json['serverUrl'] as String? ?? '',
            username: json['username'] as String? ?? '',
            password: json['password'] as String? ?? '',
            remotePath: json['remotePath'] as String? ?? '/wangcai',
          ),
        );
      case CloudSyncProtocol.s3:
        return CloudSyncConfig(
          protocol: protocol,
          s3: S3BackupConfig(
            endpoint: json['endpoint'] as String? ?? '',
            region: json['region'] as String? ?? 'us-east-1',
            bucket: json['bucket'] as String? ?? '',
            objectKey: json['objectKey'] as String? ?? 'wangcai',
            accessKeyId: json['accessKeyId'] as String? ?? '',
            secretAccessKey: json['secretAccessKey'] as String? ?? '',
            forcePathStyle: json['forcePathStyle'] as bool? ?? true,
          ),
        );
    }
  }
}
