class Lender {
  const Lender({
    required this.id,
    required this.name,
    this.balance = 0,
  });

  final String id;
  final String name;
  final double balance;

  Lender copyWith({
    String? id,
    String? name,
    double? balance,
  }) {
    return Lender(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }

  factory Lender.fromJson(Map<String, dynamic> json) {
    return Lender(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名借贷人',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
