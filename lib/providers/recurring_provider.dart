import 'dart:convert';

import 'package:finance_app/models/recurring_rule.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecurringDueItem {
  const RecurringDueItem({
    required this.ruleId,
    required this.record,
    required this.nextRunDateAfter,
  });

  final String ruleId;
  final TransactionRecord record;
  final DateTime nextRunDateAfter;
}

class RecurringProvider extends ChangeNotifier {
  RecurringProvider() {
    _loadFromLocal();
  }

  static const _storageKey = 'recurring_rules_v1';
  final List<RecurringRule> _rules = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<RecurringRule> get rules => List.unmodifiable(_rules);

  Future<void> upsertRule(RecurringRule rule) async {
    final index = _rules.indexWhere((item) => item.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
    } else {
      _rules.add(rule);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeRule(String id) async {
    _rules.removeWhere((item) => item.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<RecurringRule> rules) async {
    _rules
      ..clear()
      ..addAll(rules);
    await _persist();
    notifyListeners();
  }

  /// 仅收集到期项，不推进 nextRunDate。入账成功后再调用 [advanceAfterRecord]。
  List<RecurringDueItem> peekDueTransactions({DateTime? until}) {
    if (!_loaded) {
      return const [];
    }
    final now = until ?? DateTime.now();
    final cutoff = _dateOnly(now);
    final due = <RecurringDueItem>[];

    for (final rule in _rules) {
      if (!rule.enabled || rule.amount <= 0) {
        continue;
      }
      if (rule.type != TransactionType.expense &&
          rule.type != TransactionType.income) {
        continue;
      }

      var next = _dateOnly(rule.nextRunDate);
      var guard = 0;
      while (!next.isAfter(cutoff) && guard < 36) {
        guard++;
        if (rule.endDate != null && next.isAfter(_dateOnly(rule.endDate!))) {
          break;
        }
        final after = _nextOccurrenceAfter(rule, next);
        due.add(
          RecurringDueItem(
            ruleId: rule.id,
            nextRunDateAfter: after,
            record: TransactionRecord(
              id: 'recurring_${rule.id}_${next.millisecondsSinceEpoch}',
              type: rule.type,
              amount: rule.amount,
              category: rule.category,
              accountId: rule.accountId,
              accountName: rule.accountName,
              date: next,
              note: rule.note.isEmpty ? '周期：${rule.title}' : rule.note,
              client: TransactionClient.recurring,
            ),
          ),
        );
        next = after;
      }
    }
    return due;
  }

  Future<void> advanceAfterRecord({
    required String ruleId,
    required DateTime nextRunDateAfter,
  }) async {
    final index = _rules.indexWhere((item) => item.id == ruleId);
    if (index == -1) {
      return;
    }
    final current = _rules[index];
    final currentNext = _dateOnly(current.nextRunDate);
    final target = _dateOnly(nextRunDateAfter);
    if (target.isBefore(currentNext) || target.isAtSameMomentAs(currentNext)) {
      return;
    }
    _rules[index] = current.copyWith(nextRunDate: target);
    await _persist();
    notifyListeners();
  }

  DateTime computeInitialNextRun({
    required RecurringFrequency frequency,
    required DateTime startDate,
    required int dayOfMonth,
    required int weekday,
  }) {
    final start = _dateOnly(startDate);
    switch (frequency) {
      case RecurringFrequency.monthly:
        final candidate = DateTime(
          start.year,
          start.month,
          dayOfMonth.clamp(1, 28),
        );
        if (!candidate.isBefore(start)) {
          return candidate;
        }
        return DateTime(start.year, start.month + 1, dayOfMonth.clamp(1, 28));
      case RecurringFrequency.weekly:
        var candidate = start;
        while (candidate.weekday != weekday) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
    }
  }

  DateTime _nextOccurrenceAfter(RecurringRule rule, DateTime current) {
    final day = _dateOnly(current);
    switch (rule.frequency) {
      case RecurringFrequency.monthly:
        return DateTime(day.year, day.month + 1, rule.dayOfMonth.clamp(1, 28));
      case RecurringFrequency.weekly:
        return day.add(const Duration(days: 7));
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _rules
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(RecurringRule.fromJson),
          );
      } catch (_) {
        _rules.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_rules.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}
