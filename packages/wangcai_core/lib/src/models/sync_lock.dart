class SyncLock {
  const SyncLock({
    required this.ownerId,
    required this.acquiredAt,
    required this.expiresAt,
    this.leaseMs = defaultLeaseMs,
  });

  static const int defaultLeaseMs = 30000;

  final String ownerId;
  final DateTime acquiredAt;
  final DateTime expiresAt;
  final int leaseMs;

  bool isExpired({DateTime? now}) {
    final reference = now ?? DateTime.now().toUtc();
    return !expiresAt.toUtc().isAfter(reference);
  }

  bool ownedBy(String deviceId) => ownerId == deviceId;

  SyncLock renew({DateTime? now, int? leaseMs}) {
    final reference = (now ?? DateTime.now()).toUtc();
    final lease = leaseMs ?? this.leaseMs;
    return SyncLock(
      ownerId: ownerId,
      acquiredAt: acquiredAt,
      expiresAt: reference.add(Duration(milliseconds: lease)),
      leaseMs: lease,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'acquiredAt': acquiredAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'leaseMs': leaseMs,
    };
  }

  factory SyncLock.fromJson(Map<String, dynamic> json) {
    final lease = (json['leaseMs'] as num?)?.toInt() ?? defaultLeaseMs;
    final acquired =
        DateTime.tryParse(json['acquiredAt'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    final expires =
        DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc() ??
        acquired.add(Duration(milliseconds: lease));
    return SyncLock(
      ownerId: json['ownerId'] as String? ?? '',
      acquiredAt: acquired,
      expiresAt: expires,
      leaseMs: lease,
    );
  }

  factory SyncLock.acquire({
    required String ownerId,
    int leaseMs = defaultLeaseMs,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return SyncLock(
      ownerId: ownerId,
      acquiredAt: reference,
      expiresAt: reference.add(Duration(milliseconds: leaseMs)),
      leaseMs: leaseMs,
    );
  }
}
