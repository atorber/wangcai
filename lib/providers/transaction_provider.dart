import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider() {
    _loadFromLocal();
  }

  static const _storageKey = 'transaction_records_v1';
  final List<TransactionRecord> _transactions = [];
  bool _loaded = false;

  List<TransactionRecord> get transactions {
    final copied = List<TransactionRecord>.from(_transactions);
    copied.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(copied);
  }

  int get totalCount => _transactions.length;
  bool get loaded => _loaded;

  List<TransactionRecord> getTransactionsPage({
    required int offset,
    required int limit,
  }) {
    final sorted = transactions;
    if (offset >= sorted.length) {
      return const [];
    }
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  Future<TransactionRecord> addTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required String accountId,
    required String accountName,
    String? transferAccountId,
    String? transferAccountName,
    String? lenderId,
    String? lenderName,
    required DateTime date,
    String note = '',
  }) async {
    final record = TransactionRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      accountName: accountName,
      transferAccountId: transferAccountId,
      transferAccountName: transferAccountName,
      lenderId: lenderId,
      lenderName: lenderName,
      date: date,
      note: note,
    );
    _transactions.insert(0, record);
    await _persistToLocal();
    notifyListeners();
    return record;
  }

  Future<void> replaceAll(List<TransactionRecord> records) async {
    _transactions
      ..clear()
      ..addAll(records);
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionRecord updated) async {
    final index = _transactions.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      return;
    }
    _transactions[index] = updated;
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((item) => item.id == id);
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> replaceCategoryLabel({
    required String from,
    required String to,
  }) async {
    bool changed = false;
    for (int i = 0; i < _transactions.length; i++) {
      final item = _transactions[i];
      if (item.category != from) {
        continue;
      }
      _transactions[i] = TransactionRecord(
        id: item.id,
        type: item.type,
        amount: item.amount,
        category: to,
        accountId: item.accountId,
        accountName: item.accountName,
        transferAccountId: item.transferAccountId,
        transferAccountName: item.transferAccountName,
        lenderId: item.lenderId,
        lenderName: item.lenderName,
        date: item.date,
        note: item.note,
      );
      changed = true;
    }
    if (!changed) {
      return;
    }
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _transactions
          ..clear()
          ..addAll(
            list
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(TransactionRecord.fromJson)
                .toList(growable: false),
          );
      } catch (_) {
        _transactions.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_transactions.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_storageKey, raw);
  }
}
