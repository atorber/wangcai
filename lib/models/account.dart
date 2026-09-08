export 'package:wangcai_core/wangcai_core.dart'
    show Account, AccountType, accountTypeFromName;

import 'package:flutter/material.dart';
import 'package:wangcai_core/wangcai_core.dart';

extension AccountUi on Account {
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
}
