import 'dart:convert';

import 'package:wangcai_core/src/ledger/ledger.dart';
import 'package:wangcai_core/src/models/ledger_bundle.dart';
import 'package:wangcai_core/src/models/sync_lock.dart';
import 'package:wangcai_core/src/sync/cloud_sync_exception.dart';
import 'package:wangcai_core/src/sync/object_store.dart';

/// 基于 [ObjectStore] 的账本同步客户端：revision 对齐 + 租约锁。
class SyncClient {
  SyncClient({
    required this.store,
    required this.ownerId,
    required this.ledgerPath,
    required this.lockPath,
    this.leaseMs = SyncLock.defaultLeaseMs,
    this.lockRetry = const Duration(milliseconds: 500),
    this.lockTimeout = const Duration(seconds: 30),
  });

  final ObjectStore store;
  final String ownerId;
  final String ledgerPath;
  final String lockPath;
  final int leaseMs;
  final Duration lockRetry;
  final Duration lockTimeout;

  /// 下载远端 bundle；不存在返回 null，存在则返回其 [LedgerBundle.revision]。
  Future<int?> fetchRemoteRevision() async {
    final bundle = await downloadBundle();
    return bundle?.revision;
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
  }

  /// 若远端 revision 大于本地，则用远端覆盖 [local] 并返回同一实例。
  Future<Ledger> ensureFresh(Ledger local) async {
    final remote = await downloadBundle();
    if (remote != null && remote.revision > local.revision) {
      local.replaceAll(remote);
    }
    return local;
  }

  /// 持锁写事务：远端优先作为 mutate 前的真相源，再执行 [action]、bump、上传。
  Future<T> writeTransaction<T>(
    Ledger local,
    Future<T> Function(Ledger ledger) action,
  ) async {
    await _acquireLock();
    try {
      final remote = await downloadBundle();
      if (remote != null) {
        local.replaceAll(remote);
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
  /// 若远端 revision 更大且 [force] 为 false，抛出 `CONFLICT`。
  Future<LedgerBundle> pushLocal(Ledger local, {bool force = false}) async {
    await _acquireLock();
    try {
      final remote = await downloadBundle();
      if (remote != null && remote.revision > local.revision && !force) {
        throw CloudSyncException(
          '远端 revision (${remote.revision}) 新于本地 (${local.revision})，拒绝覆盖',
          code: 'CONFLICT',
        );
      }
      final baseRevision = remote == null
          ? local.revision
          : (remote.revision > local.revision
                ? remote.revision
                : local.revision);
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
    await _acquireLock();
    try {
      final remote = await downloadBundle();
      if (remote == null) {
        throw const CloudSyncException(
          '远端账本不存在，请先执行备份',
          code: 'NOT_FOUND',
        );
      }
      local.replaceAll(remote);
      return remote;
    } finally {
      await _releaseLock();
    }
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
        // 竞态：锁刚被删，短暂重试。
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
