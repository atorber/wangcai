import 'package:flutter/material.dart';

enum AccountType {
  debitCard,
  creditCard,
  alipay,
  wechatPay,
  cash,
  other,
}

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
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String subtitle;

  bool get isLiability => balance < 0;

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'subtitle': subtitle,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名账户',
      type: accountTypeFromName(json['type'] as String? ?? 'debitCard'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}
