import 'package:finance_app/models/transaction_record.dart';

enum StatsPeriod { week, month, year }

extension StatsPeriodLabel on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.week:
        return '周';
      case StatsPeriod.month:
        return '月';
      case StatsPeriod.year:
        return '年';
    }
  }
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final String category;
  final double amount;
  final double ratio;
}

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.date,
    required this.amount,
    required this.isPeak,
    required this.isCurrent,
  });

  final String label;
  final DateTime date;
  final double amount;
  final bool isPeak;
  final bool isCurrent;
}

class StatsSnapshot {
  const StatsSnapshot({
    required this.period,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
    required this.trendPoints,
    required this.avgDailyExpense,
    required this.expenseDeltaRatio,
    required this.previousTotalExpense,
  });

  final StatsPeriod period;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalIncome;
  final double totalExpense;
  final List<CategoryStat> categoryBreakdown;
  final List<TrendPoint> trendPoints;
  final double avgDailyExpense;

  /// 本周期相对上一周期的支出变化比例（0.1 表示 +10%，-0.12 表示 -12%）。
  /// 若上一周期无数据，返回 null。
  final double? expenseDeltaRatio;
  final double previousTotalExpense;

  bool get hasExpense => totalExpense > 0;
  bool get hasIncome => totalIncome > 0;
}

class StatsService {
  const StatsService._();

  /// 为给定周期计算统计快照。[now] 可在测试时注入固定时间。
  static StatsSnapshot build({
    required List<TransactionRecord> transactions,
    required StatsPeriod period,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final currentRange = _rangeFor(period, reference);
    final previousRange = _previousRange(period, reference);

    final currentRecords = _filter(transactions, currentRange);
    final previousRecords = _filter(transactions, previousRange);

    final currentExpense = _sumExpense(currentRecords);
    final previousExpense = _sumExpense(previousRecords);
    final currentIncome = _sumIncome(currentRecords);

    final categoryBreakdown = _categoryBreakdown(currentRecords, currentExpense);
    final trendPoints = _trendPoints(period, currentRange, currentRecords, reference);
    final avgDaily = _avgDailyExpense(currentExpense, currentRange);
    final deltaRatio = previousExpense > 0
        ? (currentExpense - previousExpense) / previousExpense
        : null;

    return StatsSnapshot(
      period: period,
      rangeStart: currentRange.$1,
      rangeEnd: currentRange.$2,
      totalIncome: currentIncome,
      totalExpense: currentExpense,
      categoryBreakdown: categoryBreakdown,
      trendPoints: trendPoints,
      avgDailyExpense: avgDaily,
      expenseDeltaRatio: deltaRatio,
      previousTotalExpense: previousExpense,
    );
  }

  static (DateTime, DateTime) _rangeFor(StatsPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case StatsPeriod.week:
        final weekday = today.weekday; // Mon = 1 ... Sun = 7
        final start = today.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 7));
        return (start, end);
      case StatsPeriod.month:
        final start = DateTime(today.year, today.month);
        final end = DateTime(today.year, today.month + 1);
        return (start, end);
      case StatsPeriod.year:
        final start = DateTime(today.year);
        final end = DateTime(today.year + 1);
        return (start, end);
    }
  }

  static (DateTime, DateTime) _previousRange(StatsPeriod period, DateTime now) {
    final current = _rangeFor(period, now);
    switch (period) {
      case StatsPeriod.week:
        final start = current.$1.subtract(const Duration(days: 7));
        return (start, current.$1);
      case StatsPeriod.month:
        final start = DateTime(current.$1.year, current.$1.month - 1);
        return (start, current.$1);
      case StatsPeriod.year:
        final start = DateTime(current.$1.year - 1);
        return (start, current.$1);
    }
  }

  static List<TransactionRecord> _filter(
    List<TransactionRecord> transactions,
    (DateTime, DateTime) range,
  ) {
    return transactions
        .where((item) => !item.date.isBefore(range.$1) && item.date.isBefore(range.$2))
        .toList(growable: false);
  }

  static double _sumExpense(List<TransactionRecord> records) {
    return records.fold<double>(0, (sum, item) {
      return item.type == TransactionType.expense ? sum + item.amount : sum;
    });
  }

  static double _sumIncome(List<TransactionRecord> records) {
    return records.fold<double>(0, (sum, item) {
      return item.type == TransactionType.income ? sum + item.amount : sum;
    });
  }

  static List<CategoryStat> _categoryBreakdown(
    List<TransactionRecord> records,
    double totalExpense,
  ) {
    if (totalExpense <= 0) {
      return const [];
    }
    final aggregate = <String, double>{};
    for (final record in records) {
      if (record.type != TransactionType.expense) {
        continue;
      }
      aggregate.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    final entries = aggregate.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (entry) => CategoryStat(
            category: entry.key,
            amount: entry.value,
            ratio: entry.value / totalExpense,
          ),
        )
        .toList(growable: false);
  }

  static List<TrendPoint> _trendPoints(
    StatsPeriod period,
    (DateTime, DateTime) range,
    List<TransactionRecord> records,
    DateTime now,
  ) {
    final buckets = _buckets(period, range);
    final amounts = List<double>.filled(buckets.length, 0);
    for (final record in records) {
      if (record.type != TransactionType.expense) {
        continue;
      }
      final idx = _bucketIndex(period, range, record.date);
      if (idx >= 0 && idx < amounts.length) {
        amounts[idx] += record.amount;
      }
    }
    double peak = 0;
    for (final amount in amounts) {
      if (amount > peak) {
        peak = amount;
      }
    }
    final today = DateTime(now.year, now.month, now.day);
    final currentIdx = _bucketIndex(period, range, today);
    final result = <TrendPoint>[];
    for (int i = 0; i < buckets.length; i++) {
      result.add(
        TrendPoint(
          label: buckets[i].$2,
          date: buckets[i].$1,
          amount: amounts[i],
          isPeak: peak > 0 && amounts[i] == peak,
          isCurrent: i == currentIdx,
        ),
      );
    }
    return result;
  }

  static List<(DateTime, String)> _buckets(
    StatsPeriod period,
    (DateTime, DateTime) range,
  ) {
    switch (period) {
      case StatsPeriod.week:
        const labels = ['一', '二', '三', '四', '五', '六', '日'];
        return List.generate(
          7,
          (i) => (range.$1.add(Duration(days: i)), labels[i]),
          growable: false,
        );
      case StatsPeriod.month:
        final daysInMonth = DateTime(range.$1.year, range.$1.month + 1, 0).day;
        return List.generate(
          daysInMonth,
          (i) => (
            DateTime(range.$1.year, range.$1.month, i + 1),
            '${i + 1}',
          ),
          growable: false,
        );
      case StatsPeriod.year:
        return List.generate(
          12,
          (i) => (DateTime(range.$1.year, i + 1), '${i + 1}月'),
          growable: false,
        );
    }
  }

  static int _bucketIndex(
    StatsPeriod period,
    (DateTime, DateTime) range,
    DateTime date,
  ) {
    if (date.isBefore(range.$1) || !date.isBefore(range.$2)) {
      return -1;
    }
    switch (period) {
      case StatsPeriod.week:
        return date.difference(range.$1).inDays;
      case StatsPeriod.month:
        return date.day - 1;
      case StatsPeriod.year:
        return date.month - 1;
    }
  }

  static double _avgDailyExpense(
    double totalExpense,
    (DateTime, DateTime) range,
  ) {
    final days = range.$2.difference(range.$1).inDays;
    if (days <= 0) {
      return 0;
    }
    return totalExpense / days;
  }
}
