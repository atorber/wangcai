import 'package:flutter/material.dart';

enum AccountType { debitCard, creditCard, alipay, wechatPay, cash, other }

AccountType accountTypeFromName(String name) {
  switch (name) {
    case 'creditCard':
      return AccountType.creditCard;
    case 'alipay':
      return AccountType.alipay;
    case 'wechatPay':
      return AccountType.wechatPay;
    case 'cash':
      return AccountType.cash;
    case 'other':
      return AccountType.other;
    default:
      return AccountType.debitCard;
  }
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.subtitle = '',
    this.creditLimit,
    this.billingDay,
    this.paymentDay,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String subtitle;

  /// 信用卡额度（仅信用卡有意义）
  final double? creditLimit;

  /// 账单日 1-28
  final int? billingDay;

  /// 还款日 1-28
  final int? paymentDay;

  bool get isLiability => balance < 0;
  bool get isCreditCard => type == AccountType.creditCard;

  /// 本期已用额度（信用卡余额为负表示欠款）
  double get usedCredit => isCreditCard ? balance.abs() : 0;

  double? get availableCredit {
    if (!isCreditCard || creditLimit == null) {
      return null;
    }
    return creditLimit! - usedCredit;
  }

  String get typeLabel {
    switch (type) {
      case AccountType.debitCard:
        return '储蓄卡';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.alipay:
        return '支付宝';
      case AccountType.wechatPay:
        return '微信支付';
      case AccountType.cash:
        return '现金';
      case AccountType.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (type) {
      case AccountType.debitCard:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.alipay:
        return Icons.account_balance_wallet;
      case AccountType.wechatPay:
        return Icons.chat;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.other:
        return Icons.more_horiz;
    }
  }

  /// 计算从 [from] 起最近一个还款日（含当天）
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
      'subtitle': subtitle,
      if (creditLimit != null) 'creditLimit': creditLimit,
      if (billingDay != null) 'billingDay': billingDay,
      if (paymentDay != null) 'paymentDay': paymentDay,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名账户',
      type: accountTypeFromName(json['type'] as String? ?? 'debitCard'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      subtitle: json['subtitle'] as String? ?? '',
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      billingDay: (json['billingDay'] as num?)?.toInt(),
      paymentDay: (json['paymentDay'] as num?)?.toInt(),
    );
  }
}
