import 'package:wangcai_core/src/models/account.dart';
import 'package:wangcai_core/src/models/budget.dart';
import 'package:wangcai_core/src/models/lender.dart';
import 'package:wangcai_core/src/models/recurring_rule.dart';
import 'package:wangcai_core/src/models/transaction_category.dart';
import 'package:wangcai_core/src/models/transaction_record.dart';

/// 云端/本地统一账本快照。schemaVersion ≥ 2 含预算与周期规则；[revision] 用于多端版本对齐。
class LedgerBundle {
  const LedgerBundle({
    required this.exportedAt,
    required this.accounts,
    required this.lenders,
    required this.categories,
    required this.transactions,
    this.budgets = const [],
    this.recurringRules = const [],
    this.version = 1,
    this.schemaVersion = currentSchemaVersion,
    this.revision = 0,
    this.deviceId,
  });

  static const int currentSchemaVersion = 2;

  final int version;
  final int schemaVersion;
  final int revision;
  final String? deviceId;
  final DateTime exportedAt;
  final List<Account> accounts;
  final List<Lender> lenders;
  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
  final List<Budget> budgets;
  final List<RecurringRule> recurringRules;

  LedgerBundle copyWith({
    int? version,
    int? schemaVersion,
    int? revision,
    String? deviceId,
    DateTime? exportedAt,
    List<Account>? accounts,
    List<Lender>? lenders,
    List<TransactionCategory>? categories,
    List<TransactionRecord>? transactions,
    List<Budget>? budgets,
    List<RecurringRule>? recurringRules,
  }) {
    return LedgerBundle(
      version: version ?? this.version,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      revision: revision ?? this.revision,
      deviceId: deviceId ?? this.deviceId,
      exportedAt: exportedAt ?? this.exportedAt,
      accounts: accounts ?? this.accounts,
      lenders: lenders ?? this.lenders,
      categories: categories ?? this.categories,
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      recurringRules: recurringRules ?? this.recurringRules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'schemaVersion': schemaVersion,
      'revision': revision,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
      'exportedAt': exportedAt.toIso8601String(),
      'accounts': accounts.map((e) => e.toJson()).toList(growable: false),
      'lenders': lenders.map((e) => e.toJson()).toList(growable: false),
      'categories': categories.map((e) => e.toJson()).toList(growable: false),
      'transactions': transactions.map((e) => e.toJson()).toList(growable: false),
      'budgets': budgets.map((e) => e.toJson()).toList(growable: false),
      'recurringRules':
          recurringRules.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory LedgerBundle.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      return (json[key] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(fromJson)
          .toList(growable: false);
    }

    return LedgerBundle(
      version: (json['version'] as num?)?.toInt() ?? 1,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      deviceId: json['deviceId'] as String?,
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      accounts: parseList('accounts', Account.fromJson),
      lenders: parseList('lenders', Lender.fromJson),
      categories: parseList('categories', TransactionCategory.fromJson),
      transactions: parseList('transactions', TransactionRecord.fromJson),
      budgets: parseList('budgets', Budget.fromJson),
      recurringRules: parseList('recurringRules', RecurringRule.fromJson),
    );
  }

  factory LedgerBundle.empty({String? deviceId}) {
    return LedgerBundle(
      exportedAt: DateTime.now(),
      deviceId: deviceId,
      accounts: const [],
      lenders: const [],
      categories: defaultCategories(),
      transactions: const [],
    );
  }
}

/// 兼容 App 旧类型名。
typedef AppBackupBundle = LedgerBundle;
