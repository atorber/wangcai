class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'iconKey': iconKey};
  }

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      label: json['label'] as String? ?? '其他',
      iconKey: json['iconKey'] as String? ?? 'other',
    );
  }
}

List<TransactionCategory> defaultCategories() => const [
  TransactionCategory(id: 'c_food', label: '餐饮', iconKey: 'food'),
  TransactionCategory(id: 'c_transport', label: '交通', iconKey: 'transport'),
  TransactionCategory(id: 'c_shopping', label: '购物', iconKey: 'shopping'),
  TransactionCategory(id: 'c_movie', label: '电影', iconKey: 'movie'),
  TransactionCategory(id: 'c_medical', label: '医疗', iconKey: 'medical'),
  TransactionCategory(id: 'c_grocery', label: '杂货', iconKey: 'grocery'),
  TransactionCategory(id: 'c_bill', label: '账单', iconKey: 'bill'),
  TransactionCategory(id: 'c_other', label: '其他', iconKey: 'other'),
];
