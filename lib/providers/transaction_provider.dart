import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionQueryFilter {
  const TransactionQueryFilter({
    this.type,
    this.types,
    this.startDate,
    this.endDate,
    this.keyword,
  });

  final TransactionType? type;
  final Set<TransactionType>? types;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? keyword;
}

class TransactionProvider extends ChangeNotifier {
  TransactionProvider() {
    _loadFromLocal();
  }

  static const _storageKey = 'transaction_records_v1';
  final List<TransactionRecord> _transactions = [];
  bool _loaded = false;
  List<TransactionRecord>? _sortedCache;

  List<TransactionRecord> _sortedTransactions() {
    final cached = _sortedCache;
    if (cached != null) {
      return cached;
    }
    final copied = List<TransactionRecord>.from(_transactions);
    copied.sort((a, b) => b.date.compareTo(a.date));
    _sortedCache = copied;
    return copied;
  }

  void _markCacheDirty() {
    _sortedCache = null;
  }

  List<TransactionRecord> get transactions {
    return List.unmodifiable(_sortedTransactions());
  }

  int get totalCount => _transactions.length;
  bool get loaded => _loaded;

  List<TransactionRecord> getTransactionsPage({
    required int offset,
    required int limit,
  }) {
    return queryPage(
      offset: offset,
      limit: limit,
      filter: const TransactionQueryFilter(),
    );
  }

  List<TransactionRecord> queryPage({
    required int offset,
    required int limit,
    required TransactionQueryFilter filter,
  }) {
    final sorted = _sortedTransactions();
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    final start = filter.startDate;
    final end = filter.endDate;
    final hasKeyword = keyword.isNotEmpty;

    int skipped = 0;
    final result = <TransactionRecord>[];
    for (final item in sorted) {
      if (filter.type != null && item.type != filter.type) {
        continue;
      }
      if (filter.types != null && !filter.types!.contains(item.type)) {
        continue;
      }
      if (start != null && item.date.isBefore(start)) {
        continue;
      }
      if (end != null && item.date.isAfter(end)) {
        continue;
      }
      if (hasKeyword && !_matchesKeyword(item, keyword)) {
        continue;
      }
      if (skipped < offset) {
        skipped++;
        continue;
      }
      result.add(item);
      if (result.length >= limit) {
        break;
      }
    }
    return result;
  }

  int countByFilter(TransactionQueryFilter filter) {
    final sorted = _sortedTransactions();
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    final start = filter.startDate;
    final end = filter.endDate;
    final hasKeyword = keyword.isNotEmpty;
    int count = 0;
    for (final item in sorted) {
      if (filter.type != null && item.type != filter.type) {
        continue;
      }
      if (filter.types != null && !filter.types!.contains(item.type)) {
        continue;
      }
      if (start != null && item.date.isBefore(start)) {
        continue;
      }
      if (end != null && item.date.isAfter(end)) {
        continue;
      }
      if (hasKeyword && !_matchesKeyword(item, keyword)) {
        continue;
      }
      count++;
    }
    return count;
  }

  bool _matchesKeyword(TransactionRecord item, String keyword) {
    return item.category.toLowerCase().contains(keyword) ||
        item.accountName.toLowerCase().contains(keyword) ||
        (item.transferAccountName?.toLowerCase().contains(keyword) ?? false) ||
        (item.lenderName?.toLowerCase().contains(keyword) ?? false) ||
        item.note.toLowerCase().contains(keyword);
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
    _markCacheDirty();
    await _persistToLocal();
    notifyListeners();
    return record;
  }

  Future<void> replaceAll(List<TransactionRecord> records) async {
    _transactions
      ..clear()
      ..addAll(records);
    _markCacheDirty();
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionRecord updated) async {
    final index = _transactions.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      return;
    }
    _transactions[index] = updated;
    _markCacheDirty();
    await _persistToLocal();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((item) => item.id == id);
    _markCacheDirty();
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
    _markCacheDirty();
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
        _markCacheDirty();
      } catch (_) {
        _transactions.clear();
        _markCacheDirty();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      _transactions.map((e) => e.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey, raw);
  }
}
