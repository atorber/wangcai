import 'package:flutter/material.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;

  IconData get icon => iconDataFromKey(iconKey);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'iconKey': iconKey,
    };
  }

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      label: json['label'] as String? ?? '其他',
      iconKey: json['iconKey'] as String? ?? 'other',
    );
  }
}

IconData iconDataFromKey(String key) {
  switch (key) {
    case 'food':
      return Icons.restaurant;
    case 'transport':
      return Icons.directions_car;
    case 'shopping':
      return Icons.shopping_bag;
    case 'movie':
      return Icons.confirmation_number;
    case 'medical':
      return Icons.medical_services;
    case 'grocery':
      return Icons.local_grocery_store;
    case 'bill':
      return Icons.bolt;
    default:
      return Icons.grid_view;
  }
}
