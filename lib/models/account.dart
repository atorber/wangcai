export 'package:wangcai_core/wangcai_core.dart'
    show Account, AccountType, accountTypeFromName, accountTypeLabel;

import 'package:flutter/material.dart';
import 'package:wangcai_core/wangcai_core.dart';

extension AccountUi on Account {
  IconData get icon => iconForAccountType(type);
}

IconData iconForAccountType(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return Icons.payments;
    case AccountType.creditCard:
      return Icons.credit_score;
    case AccountType.debitCard:
      return Icons.account_balance;
    case AccountType.onlineAccount:
      return Icons.language;
    case AccountType.investment:
      return Icons.show_chart;
    case AccountType.storedValueCard:
      return Icons.confirmation_number_outlined;
  }
}
