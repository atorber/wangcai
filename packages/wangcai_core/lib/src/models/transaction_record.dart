enum TransactionType { expense, income, transfer, lend, borrow }

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

/// 记账操作端（写入账单的客户端）。
///
/// JSON 值：`app` | `agent` | `import` | `recurring`；缺省/未知为 `unknown`。
enum TransactionClient {
  app,
  agent,
  csvImport,
  recurring,
  unknown,
}

TransactionClient transactionClientFromName(String? name) {
  switch (name) {
    case 'app':
      return TransactionClient.app;
    case 'agent':
    case 'cli':
    case 'skill':
      return TransactionClient.agent;
    case 'import':
    case 'csvImport':
      return TransactionClient.csvImport;
    case 'recurring':
      return TransactionClient.recurring;
    default:
      return TransactionClient.unknown;
  }
}

String transactionClientToJson(TransactionClient client) {
  switch (client) {
    case TransactionClient.app:
      return 'app';
    case TransactionClient.agent:
      return 'agent';
    case TransactionClient.csvImport:
      return 'import';
    case TransactionClient.recurring:
      return 'recurring';
    case TransactionClient.unknown:
      return 'unknown';
  }
}

String transactionClientLabel(TransactionClient client) {
  switch (client) {
    case TransactionClient.app:
      return 'App';
    case TransactionClient.agent:
      return 'Agent';
    case TransactionClient.csvImport:
      return '导入';
    case TransactionClient.recurring:
      return '周期';
    case TransactionClient.unknown:
      return '未知';
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
    this.client = TransactionClient.unknown,
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
  final TransactionClient client;

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
      'client': transactionClientToJson(client),
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
      client: transactionClientFromName(json['client'] as String?),
    );
  }
}
