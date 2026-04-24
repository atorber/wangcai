enum TransactionType {
  expense,
  income,
  transfer,
  lend,
  borrow,
}

TransactionType transactionTypeFromName(String name) {
  switch (name) {
    case 'income':
      return TransactionType.income;
    case 'transfer':
      return TransactionType.transfer;
    case 'lend':
      return TransactionType.lend;
    case 'borrow':
      return TransactionType.borrow;
    default:
      return TransactionType.expense;
  }
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.accountName,
    this.transferAccountId,
    this.transferAccountName,
    this.lenderId,
    this.lenderName,
    required this.date,
    this.note = '',
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final String accountId;
  final String accountName;
  final String? transferAccountId;
  final String? transferAccountName;
  final String? lenderId;
  final String? lenderName;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'category': category,
      'accountId': accountId,
      'accountName': accountName,
      'transferAccountId': transferAccountId,
      'transferAccountName': transferAccountName,
      'lenderId': lenderId,
      'lenderName': lenderName,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      type: transactionTypeFromName(json['type'] as String? ?? 'expense'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '其他',
      accountId: json['accountId'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '未命名账户',
      transferAccountId: json['transferAccountId'] as String?,
      transferAccountName: json['transferAccountName'] as String?,
      lenderId: json['lenderId'] as String?,
      lenderName: json['lenderName'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}
