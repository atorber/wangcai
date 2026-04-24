import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:finance_app/models/transaction_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider() {
    _loadFromLocal();
  }

  static const _storageKey = 'transaction_categories_v1';
  final List<TransactionCategory> _categories = [];
  bool _loaded = false;

  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  bool get loaded => _loaded;

  Future<void> replaceAll(List<TransactionCategory> categories) async {
    _categories
      ..clear()
      ..addAll(categories);
    await _persist();
    notifyListeners();
  }

  Future<void> addCategory({
    required String label,
    required String iconKey,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final exists = _categories.any((item) => item.label == trimmed);
    if (exists) {
      return;
    }
    _categories.add(
      TransactionCategory(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        label: trimmed,
        iconKey: iconKey,
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateCategory({
    required String id,
    required String label,
    required String iconKey,
  }) async {
    final index = _categories.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _categories[index] = TransactionCategory(
      id: _categories[index].id,
      label: trimmed,
      iconKey: iconKey,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removeCategory(String id) async {
    _categories.removeWhere((item) => item.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _categories
        ..clear()
        ..addAll(_defaultCategories);
      await _persist();
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _categories
        ..clear()
        ..addAll(
          list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map(TransactionCategory.fromJson)
              .toList(growable: false),
        );
    } catch (_) {
      _categories
        ..clear()
        ..addAll(_defaultCategories);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_categories.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_storageKey, raw);
  }

  List<TransactionCategory> get _defaultCategories => const [
        TransactionCategory(id: 'c_food', label: '餐饮', iconKey: 'food'),
        TransactionCategory(id: 'c_transport', label: '交通', iconKey: 'transport'),
        TransactionCategory(id: 'c_shopping', label: '购物', iconKey: 'shopping'),
        TransactionCategory(id: 'c_movie', label: '电影', iconKey: 'movie'),
        TransactionCategory(id: 'c_medical', label: '医疗', iconKey: 'medical'),
        TransactionCategory(id: 'c_grocery', label: '杂货', iconKey: 'grocery'),
        TransactionCategory(id: 'c_bill', label: '账单', iconKey: 'bill'),
        TransactionCategory(id: 'c_other', label: '其他', iconKey: 'other'),
      ];
}
