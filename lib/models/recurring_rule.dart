import 'package:finance_app/models/transaction_record.dart';

enum RecurringFrequency { monthly, weekly }

RecurringFrequency recurringFrequencyFromName(String name) {
  switch (name) {
    case 'weekly':
      return RecurringFrequency.weekly;
    default:
      return RecurringFrequency.monthly;
  }
}

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.frequency,
    required this.startDate,
    required this.nextRunDate,
    this.dayOfMonth = 1,
    this.weekday = DateTime.monday,
    this.endDate,
    this.enabled = true,
    this.note = '',
  });

  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String category;
  final String accountId;
  final String accountName;
  final RecurringFrequency frequency;
  final int dayOfMonth;
  final int weekday;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunDate;
  final bool enabled;
  final String note;

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.monthly:
        return '每月$dayOfMonth日';
      case RecurringFrequency.weekly:
        return '每周${_weekdayLabel(weekday)}';
    }
  }

  RecurringRule copyWith({
    String? title,
    TransactionType? type,
    double? amount,
    String? category,
    String? accountId,
    String? accountName,
    RecurringFrequency? frequency,
    int? dayOfMonth,
    int? weekday,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunDate,
    bool? enabled,
    String? note,
    bool clearEndDate = false,
  }) {
    return RecurringRule(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      nextRunDate: nextRunDate ?? this.nextRunDate,
      enabled: enabled ?? this.enabled,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'category': category,
      'accountId': accountId,
      'accountName': accountName,
      'frequency': frequency.name,
      'dayOfMonth': dayOfMonth,
      'weekday': weekday,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextRunDate': nextRunDate.toIso8601String(),
      'enabled': enabled,
      'note': note,
    };
  }

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '周期账单',
      type: transactionTypeFromName(json['type'] as String? ?? 'expense'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '其他',
      accountId: json['accountId'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '未命名账户',
      frequency: recurringFrequencyFromName(
        json['frequency'] as String? ?? 'monthly',
      ),
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt() ?? 1,
      weekday: (json['weekday'] as num?)?.toInt() ?? DateTime.monday,
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      nextRunDate:
          DateTime.tryParse(json['nextRunDate'] as String? ?? '') ??
          DateTime.now(),
      enabled: json['enabled'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final index = (weekday - 1).clamp(0, 6);
    return labels[index];
  }
}
