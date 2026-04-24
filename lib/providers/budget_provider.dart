import 'dart:convert';

import 'package:finance_app/models/budget.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetProvider() {
    _loadFromLocal();
  }

  static const _storageKey = 'budget_items_v1';
  final List<Budget> _budgets = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Budget> get budgets => List.unmodifiable(_budgets);

  Budget? findByCategoryId(String categoryId) {
    for (final item in _budgets) {
      if (item.categoryId == categoryId) {
        return item;
      }
    }
    return null;
  }

  Future<void> upsertBudget({
    required String categoryId,
    required double monthlyLimit,
  }) async {
    final normalized = monthlyLimit < 0 ? 0.0 : monthlyLimit;
    final index = _budgets.indexWhere((item) => item.categoryId == categoryId);
    if (index >= 0) {
      _budgets[index] = Budget(
        categoryId: categoryId,
        monthlyLimit: normalized,
      );
    } else {
      _budgets.add(Budget(categoryId: categoryId, monthlyLimit: normalized));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeBudget(String categoryId) async {
    _budgets.removeWhere((item) => item.categoryId == categoryId);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<Budget> budgets) async {
    _budgets
      ..clear()
      ..addAll(budgets);
    await _persist();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _budgets
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(Budget.fromJson),
          );
      } catch (_) {
        _budgets.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_budgets.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}
