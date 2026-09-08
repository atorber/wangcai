class Budget {
  const Budget({required this.categoryId, required this.monthlyLimit});

  final String categoryId;
  final double monthlyLimit;

  Map<String, dynamic> toJson() {
    return {'categoryId': categoryId, 'monthlyLimit': monthlyLimit};
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      categoryId: json['categoryId'] as String? ?? '',
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
    );
  }
}
