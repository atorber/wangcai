import 'dart:convert';

import 'package:wangcai_core/src/ledger/ledger.dart';
import 'package:wangcai_core/src/models/ledger_bundle.dart';
import 'package:wangcai_core/src/models/sync_lock.dart';
import 'package:wangcai_core/src/sync/cloud_sync_exception.dart';
import 'package:wangcai_core/src/sync/object_store.dart';

/// 远端独立版本文件内容。
class RemoteRevisionInfo {
  const RemoteRevisionInfo({
    required this.revision,
    this.deviceId,
    this.updatedAt,
  });

  final int revision;
  final String? deviceId;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'revision': revision,
    if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
  };

  factory RemoteRevisionInfo.fromJson(Map<String, dynamic> json) {
    return RemoteRevisionInfo(
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      deviceId: json['deviceId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc(),
    );
  }
}

/// 基于 [ObjectStore] 的账本同步客户端：独立 revision 文件 + 租约锁。
class SyncClient {
  SyncClient({
    required this.store,
    required this.ownerId,
    required this.ledgerPath,
    required this.revisionPath,
    required this.lockPath,
    this.leaseMs = SyncLock.defaultLeaseMs,
    this.lockRetry = const Duration(milliseconds: 500),
    this.lockTimeout = const Duration(seconds: 30),
  });

  final ObjectStore store;
  final String ownerId;
  final String ledgerPath;
  final String revisionPath;
  final String lockPath;
  final int leaseMs;
  final Duration lockRetry;
  final Duration lockTimeout;

  /// 读取远端版本：取 [revisionPath] 与账本内嵌 revision 的较大值。
  /// 避免旧客户端只更新 records、未写 revision 文件时，新客户端误判版本。
  Future<int?> fetchRemoteRevision() async {
    final fromFile = await _readRevisionFile();
    final bundle = await downloadBundle();
    return _maxRevision(fromFile?.revision, bundle?.revision);
  }

  Future<LedgerBundle?> downloadBundle() async {
    final bytes = await store.get(ledgerPath);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final text = utf8.decode(bytes);
    if (text.trim().isEmpty) {
      return null;
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const CloudSyncException('远端账本格式错误，无法解析 JSON');
    }
    if (decoded is! Map) {
      throw const CloudSyncException('远端账本结构无效');
    }
    return LedgerBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> uploadBundle(LedgerBundle bundle) async {
    final payload = utf8.encode(jsonEncode(bundle.toJson()));
    await store.put(
      ledgerPath,
      payload,
      contentType: 'application/json',
    );
    await _writeRevisionFile(
      RemoteRevisionInfo(
        revision: bundle.revision,
        deviceId: bundle.deviceId,
        updatedAt: bundle.exportedAt.toUtc(),
      ),
    );
  }

  /// 若远端 revision 大于本地，则用远端覆盖 [local] 并返回同一实例。
  Future<Ledger> ensureFresh(Ledger local) async {
    final fromFile = await _readRevisionFile();
    final remote = await downloadBundle();
    final remoteRevision = _maxRevision(fromFile?.revision, remote?.revision);
    if (remote == null ||
        remoteRevision == null ||
        remoteRevision <= local.revision) {
      return local;
    }
    local.replaceAll(
      remote.revision >= remoteRevision
          ? remote
          : remote.copyWith(revision: remoteRevision),
    );
    return local;
  }

  /// 持锁写事务：按 revision 选底稿，再执行 [action]、bump、上传。
  Future<T> writeTransaction<T>(
    Ledger local,
    Future<T> Function(Ledger ledger) action,
  ) async {
    await _acquireLock();
    try {
      final fromFile = await _readRevisionFile();
      final remote = await downloadBundle();
      final remoteRevision = _maxRevision(fromFile?.revision, remote?.revision);
      if (remote != null &&
          remoteRevision != null &&
          remoteRevision > local.revision) {
        local.replaceAll(
          remote.revision >= remoteRevision
              ? remote
              : remote.copyWith(revision: remoteRevision),
        );
      }
      final result = await action(local);
      local.bumpRevision(deviceId: ownerId);
      await uploadBundle(local.toBundle());
      return result;
    } finally {
      await _releaseLock();
    }
  }

  /// App「立即备份」：持锁后以本地内容覆盖远端。
  Future<LedgerBundle> pushLocal(Ledger local, {bool force = false}) async {
    await _acquireLock();
    try {
      final fromFile = await _readRevisionFile();
      final remote = await downloadBundle();
      final remoteRevision =
          _maxRevision(fromFile?.revision, remote?.revision) ?? 0;
      if (remoteRevision > local.revision && !force) {
        throw CloudSyncException(
          '远端 revision ($remoteRevision) 新于本地 (${local.revision})，拒绝覆盖',
          code: 'CONFLICT',
        );
      }
      final baseRevision = remoteRevision > local.revision
          ? remoteRevision
          : local.revision;
      local.revision = baseRevision;
      local.bumpRevision(deviceId: ownerId);
      final bundle = local.toBundle();
      await uploadBundle(bundle);
      return bundle;
    } finally {
      await _releaseLock();
    }
  }

  /// App「恢复覆盖」：持锁拉取远端并写入 [local]。
  Future<LedgerBundle> pullReplace(Ledger local) async {
    var locked = false;
    try {
      await _acquireLock();
      locked = true;
    } on CloudSyncException {
      locked = false;
    }
    try {
      final fromFile = await _readRevisionFile();
      final remote = await downloadBundle();
      if (remote == null) {
        throw const CloudSyncException(
          '远端账本不存在，请先执行备份',
          code: 'NOT_FOUND',
        );
      }
      final remoteRevision = _maxRevision(fromFile?.revision, remote.revision);
      if (remoteRevision != null && remoteRevision > remote.revision) {
        local.replaceAll(remote.copyWith(revision: remoteRevision));
        return local.toBundle();
      }
      local.replaceAll(remote);
      // replaceAll 会 ensureOpening + 按流水重算余额，须返回本地快照而非原始 remote。
      return local.toBundle();
    } finally {
      if (locked) {
        await _releaseLock();
      }
    }
  }

  int? _maxRevision(int? a, int? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a > b ? a : b;
  }

  Future<RemoteRevisionInfo?> _readRevisionFile() async {
    final bytes = await store.get(revisionPath);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        return null;
      }
      return RemoteRevisionInfo.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeRevisionFile(RemoteRevisionInfo info) async {
    final payload = utf8.encode(jsonEncode(info.toJson()));
    await store.put(
      revisionPath,
      payload,
      contentType: 'application/json',
    );
  }

  Future<void> _acquireLock() async {
    final deadline = DateTime.now().toUtc().add(lockTimeout);
    while (true) {
      final candidate = SyncLock.acquire(ownerId: ownerId, leaseMs: leaseMs);
      final payload = utf8.encode(jsonEncode(candidate.toJson()));
      final created = await store.putIfAbsent(
        lockPath,
        payload,
        contentType: 'application/json',
      );
      if (created) {
        return;
      }

      final existing = await _readLock();
      if (existing == null) {
        if (!_hasTimeLeft(deadline)) {
          throw const CloudSyncException(
            '获取同步锁超时：远端锁忙碌',
            code: 'LOCK_BUSY',
          );
        }
        await Future<void>.delayed(lockRetry);
        continue;
      }

      if (existing.isExpired()) {
        await store.put(
          lockPath,
          payload,
          contentType: 'application/json',
        );
        return;
      }

      if (existing.ownedBy(ownerId)) {
        final renewed = existing.renew(leaseMs: leaseMs);
        await store.put(
          lockPath,
          utf8.encode(jsonEncode(renewed.toJson())),
          contentType: 'application/json',
        );
        return;
      }

      if (!_hasTimeLeft(deadline)) {
        throw const CloudSyncException(
          '获取同步锁超时：远端锁忙碌',
          code: 'LOCK_BUSY',
        );
      }
      await Future<void>.delayed(lockRetry);
    }
  }

  Future<void> _releaseLock() async {
    final existing = await _readLock();
    if (existing == null) {
      return;
    }
    if (!existing.ownedBy(ownerId)) {
      return;
    }
    await store.delete(lockPath);
  }

  Future<SyncLock?> _readLock() async {
    final bytes = await store.get(lockPath);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        return null;
      }
      return SyncLock.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  bool _hasTimeLeft(DateTime deadlineUtc) =>
      DateTime.now().toUtc().isBefore(deadlineUtc);
}
