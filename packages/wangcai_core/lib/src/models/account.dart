enum AccountType {
  cash,
  creditCard,
  debitCard,
  onlineAccount,
  investment,
  storedValueCard,
}

AccountType accountTypeFromName(String name) {
  switch (name) {
    case 'creditCard':
      return AccountType.creditCard;
    case 'cash':
      return AccountType.cash;
    case 'onlineAccount':
    // Legacy values migrated to 网络账户.
    case 'alipay':
    case 'wechatPay':
    case 'wechat':
    case 'other':
    // 应收/应付已统一为借贷人（Lender），旧账户类型按网络账户兜底。
    case 'receivablePayable':
      return AccountType.onlineAccount;
    case 'investment':
      return AccountType.investment;
    case 'storedValueCard':
      return AccountType.storedValueCard;
    case 'debitCard':
    default:
      return AccountType.debitCard;
  }
}

String accountTypeLabel(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return '现金';
    case AccountType.creditCard:
      return '信用卡';
    case AccountType.debitCard:
      return '储蓄卡/借记卡';
    case AccountType.onlineAccount:
      return '网络账户';
    case AccountType.investment:
      return '投资账户';
    case AccountType.storedValueCard:
      return '储值卡';
  }
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    double? openingBalance,
    this.openingBalanceNeedsMigration = false,
    this.subtitle = '',
    this.creditLimit,
    this.billingDay,
    this.paymentDay,
  }) : openingBalance = openingBalance ?? balance;

  final String id;
  final String name;
  final AccountType type;
  final double balance;

  /// 期初余额（不含流水）。当前余额 = openingBalance + 流水净额。
  final double openingBalance;

  /// JSON 缺 openingBalance 时为 true，由 Ledger.ensureOpeningBalances 推导。
  final bool openingBalanceNeedsMigration;

  final String subtitle;
  final double? creditLimit;
  final int? billingDay;
  final int? paymentDay;

  bool get isLiability => balance < 0;
  bool get isCreditCard => type == AccountType.creditCard;
  double get usedCredit => isCreditCard ? balance.abs() : 0;

  double? get availableCredit {
    if (!isCreditCard || creditLimit == null) {
      return null;
    }
    return creditLimit! - usedCredit;
  }

  String get typeLabel => accountTypeLabel(type);

  DateTime? nextPaymentDate({DateTime? from}) {
    if (paymentDay == null) {
      return null;
    }
    final base = from ?? DateTime.now();
    final day = paymentDay!.clamp(1, 28);
    final thisMonth = DateTime(base.year, base.month, day);
    if (!thisMonth.isBefore(DateTime(base.year, base.month, base.day))) {
      return thisMonth;
    }
    return DateTime(base.year, base.month + 1, day);
  }

  int? daysUntilPayment({DateTime? from}) {
    final next = nextPaymentDate(from: from);
    if (next == null) {
      return null;
    }
    final base = from ?? DateTime.now();
    return DateTime(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime(base.year, base.month, base.day)).inDays;
  }

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    double? openingBalance,
    bool? openingBalanceNeedsMigration,
    String? subtitle,
    double? creditLimit,
    int? billingDay,
    int? paymentDay,
    bool clearCreditLimit = false,
    bool clearBillingDay = false,
    bool clearPaymentDay = false,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceNeedsMigration:
          openingBalanceNeedsMigration ?? this.openingBalanceNeedsMigration,
      subtitle: subtitle ?? this.subtitle,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
      billingDay: clearBillingDay ? null : (billingDay ?? this.billingDay),
      paymentDay: clearPaymentDay ? null : (paymentDay ?? this.paymentDay),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'openingBalance': openingBalance,
      'subtitle': subtitle,
      if (creditLimit != null) 'creditLimit': creditLimit,
      if (billingDay != null) 'billingDay': billingDay,
      if (paymentDay != null) 'paymentDay': paymentDay,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    final balance = (json['balance'] as num?)?.toDouble() ?? 0;
    final hasOpening = json.containsKey('openingBalance');
    return Account(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名账户',
      type: accountTypeFromName(json['type'] as String? ?? 'debitCard'),
      balance: balance,
      openingBalance: hasOpening
          ? (json['openingBalance'] as num?)?.toDouble() ?? balance
          : balance,
      openingBalanceNeedsMigration: !hasOpening,
      subtitle: json['subtitle'] as String? ?? '',
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      billingDay: (json['billingDay'] as num?)?.toInt(),
      paymentDay: (json['paymentDay'] as num?)?.toInt(),
    );
  }
}
