import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountProvider extends ChangeNotifier {
  AccountProvider() {
    _loadFromLocal();
  }

  static const _accountsStorageKey = 'accounts_v1';
  static const _lendersStorageKey = 'lenders_v1';
  final List<Account> _accounts = [
    const Account(
      id: 'debit-default',
      name: '招商银行储蓄卡',
      subtitle: '尾号 4392',
      type: AccountType.debitCard,
      balance: 1000,
    ),
    const Account(
      id: 'credit-default',
      name: '浦发银行信用卡',
      subtitle: '尾号 1024',
      type: AccountType.creditCard,
      balance: 0,
    ),
    const Account(
      id: 'alipay-default',
      name: '支付宝',
      type: AccountType.alipay,
      balance: 0,
    ),
    const Account(
      id: 'wechat-default',
      name: '微信支付',
      type: AccountType.wechatPay,
      balance: 0,
    ),
    const Account(
      id: 'cash-default',
      name: '现金',
      subtitle: '随身现金',
      type: AccountType.cash,
      balance: 0,
    ),
  ];
  final List<Lender> _lenders = [];
  bool _loaded = false;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Lender> get lenders => List.unmodifiable(_lenders);
  bool get loaded => _loaded;

  double get totalAssets => _accounts.fold(
        0,
        (sum, account) => account.balance > 0 ? sum + account.balance : sum,
      );

  double get totalLiabilities => _accounts.fold(
        0,
        (sum, account) => account.balance < 0 ? sum + account.balance.abs() : sum,
      );

  double get netAssets => totalAssets - totalLiabilities;

  void addAccount({
    required String name,
    required AccountType type,
    required double balance,
  }) {
    final account = Account(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      balance: balance,
    );
    _accounts.add(account);
    _persistAccountsToLocal();
    notifyListeners();
  }

  bool removeAccount(
    String id, {
    Iterable<TransactionRecord> relatedTransactions = const [],
  }) {
    final hasLinkedTransaction = relatedTransactions.any(
      (item) => item.accountId == id || item.transferAccountId == id,
    );
    if (hasLinkedTransaction) {
      return false;
    }
    _accounts.removeWhere((account) => account.id == id);
    _persistAccountsToLocal();
    notifyListeners();
    return true;
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required double balance,
  }) async {
    final index = _accounts.indexWhere((account) => account.id == id);
    if (index == -1) {
      return;
    }
    final current = _accounts[index];
    _accounts[index] = Account(
      id: current.id,
      name: name,
      type: current.type,
      balance: balance,
      subtitle: current.subtitle,
    );
    await _persistAccountsToLocal();
    notifyListeners();
  }

  Future<void> replaceAll(List<Account> accounts) async {
    _accounts
      ..clear()
      ..addAll(accounts);
    await _persistAccountsToLocal();
    notifyListeners();
  }

  Future<void> replaceLenders(List<Lender> lenders) async {
    _lenders
      ..clear()
      ..addAll(lenders);
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> addLender(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final exists = _lenders.any((item) => item.name == trimmed);
    if (exists) {
      return;
    }
    _lenders.add(
      Lender(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
      ),
    );
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> updateLender({
    required String id,
    required String name,
    required double balance,
  }) async {
    final index = _lenders.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    _lenders[index] = _lenders[index].copyWith(
      name: name.trim().isEmpty ? _lenders[index].name : name.trim(),
      balance: balance,
    );
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> applyTransaction(TransactionRecord record) async {
    _applyTransactionDelta(record, isRevert: false);
    await _persistAccountsToLocal();
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> revertTransaction(TransactionRecord record) async {
    _applyTransactionDelta(record, isRevert: true);
    await _persistAccountsToLocal();
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> applyTransactionUpdate({
    required TransactionRecord oldRecord,
    required TransactionRecord newRecord,
  }) async {
    _applyTransactionDelta(oldRecord, isRevert: true);
    _applyTransactionDelta(newRecord, isRevert: false);
    await _persistAccountsToLocal();
    await _persistLendersToLocal();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final accountRaw = prefs.getString(_accountsStorageKey);
    if (accountRaw != null && accountRaw.isNotEmpty) {
      try {
        final list = jsonDecode(accountRaw) as List<dynamic>;
        _accounts
          ..clear()
          ..addAll(
            list
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(Account.fromJson)
                .toList(growable: false),
          );
      } catch (_) {
        // keep defaults
      }
    }
    final lenderRaw = prefs.getString(_lendersStorageKey);
    if (lenderRaw != null && lenderRaw.isNotEmpty) {
      try {
        final list = jsonDecode(lenderRaw) as List<dynamic>;
        _lenders
          ..clear()
          ..addAll(
            list
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(Lender.fromJson)
                .toList(growable: false),
          );
      } catch (_) {
        _lenders.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistAccountsToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_accounts.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_accountsStorageKey, raw);
  }

  Future<void> _persistLendersToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_lenders.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_lendersStorageKey, raw);
  }

  void _applyTransactionDelta(TransactionRecord record, {required bool isRevert}) {
    final sign = isRevert ? -1.0 : 1.0;
    switch (record.type) {
      case TransactionType.expense:
        _adjustAccount(record.accountId, -record.amount * sign);
        break;
      case TransactionType.income:
        _adjustAccount(record.accountId, record.amount * sign);
        break;
      case TransactionType.transfer:
        _adjustAccount(record.accountId, -record.amount * sign);
        if (record.transferAccountId != null && record.transferAccountId!.isNotEmpty) {
          _adjustAccount(record.transferAccountId!, record.amount * sign);
        }
        break;
      case TransactionType.lend:
        _adjustAccount(record.accountId, -record.amount * sign);
        if (record.lenderId != null && record.lenderId!.isNotEmpty) {
          _adjustLender(record.lenderId!, record.amount * sign);
        }
        break;
      case TransactionType.borrow:
        _adjustAccount(record.accountId, record.amount * sign);
        if (record.lenderId != null && record.lenderId!.isNotEmpty) {
          _adjustLender(record.lenderId!, -record.amount * sign);
        }
        break;
    }
  }

  void _adjustAccount(String id, double delta) {
    final index = _accounts.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final account = _accounts[index];
    _accounts[index] = Account(
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance + delta,
      subtitle: account.subtitle,
    );
  }

  void _adjustLender(String id, double delta) {
    final index = _lenders.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final lender = _lenders[index];
    _lenders[index] = lender.copyWith(balance: lender.balance + delta);
  }
}
