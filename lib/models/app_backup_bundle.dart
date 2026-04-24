import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_category.dart';
import 'package:finance_app/models/transaction_record.dart';

class AppBackupBundle {
  const AppBackupBundle({
    required this.version,
    required this.exportedAt,
    required this.accounts,
    required this.lenders,
    required this.categories,
    required this.transactions,
    this.schemaVersion = 1,
    this.deviceId,
  });

  final int version;
  final DateTime exportedAt;
  final List<Account> accounts;
  final List<Lender> lenders;
  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
  final int schemaVersion;
  final String? deviceId;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'schemaVersion': schemaVersion,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
      'exportedAt': exportedAt.toIso8601String(),
      'accounts': accounts.map((e) => e.toJson()).toList(growable: false),
      'lenders': lenders.map((e) => e.toJson()).toList(growable: false),
      'categories': categories.map((e) => e.toJson()).toList(growable: false),
      'transactions': transactions.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory AppBackupBundle.fromJson(Map<String, dynamic> json) {
    final accountList = (json['accounts'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(Account.fromJson)
        .toList(growable: false);
    final categoryList = (json['categories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(TransactionCategory.fromJson)
        .toList(growable: false);
    final lenderList = (json['lenders'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(Lender.fromJson)
        .toList(growable: false);
    final transactionList = (json['transactions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(TransactionRecord.fromJson)
        .toList(growable: false);

    return AppBackupBundle(
      version: (json['version'] as num?)?.toInt() ?? 1,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      deviceId: json['deviceId'] as String?,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now(),
      accounts: accountList,
      lenders: lenderList,
      categories: categoryList,
      transactions: transactionList,
    );
  }
}
