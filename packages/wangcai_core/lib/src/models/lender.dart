class Lender {
  const Lender({
    required this.id,
    required this.name,
    this.balance = 0,
    double? openingBalance,
    this.openingBalanceNeedsMigration = false,
  }) : openingBalance = openingBalance ?? balance;

  final String id;
  final String name;
  final double balance;

  /// 期初余额（不含流水）。当前余额 = openingBalance + 流水净额。
  final double openingBalance;

  /// JSON 缺 openingBalance 时为 true，由 Ledger.ensureOpeningBalances 推导。
  final bool openingBalanceNeedsMigration;

  Lender copyWith({
    String? id,
    String? name,
    double? balance,
    double? openingBalance,
    bool? openingBalanceNeedsMigration,
  }) {
    return Lender(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceNeedsMigration:
          openingBalanceNeedsMigration ?? this.openingBalanceNeedsMigration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'openingBalance': openingBalance,
    };
  }

  factory Lender.fromJson(Map<String, dynamic> json) {
    final balance = (json['balance'] as num?)?.toDouble() ?? 0;
    final hasOpening = json.containsKey('openingBalance');
    return Lender(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名应收/应付',
      balance: balance,
      openingBalance: hasOpening
          ? (json['openingBalance'] as num?)?.toDouble() ?? balance
          : balance,
      openingBalanceNeedsMigration: !hasOpening,
    );
  }
}
