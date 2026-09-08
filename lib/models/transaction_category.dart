export 'package:wangcai_core/wangcai_core.dart'
    show TransactionCategory, defaultCategories;

import 'package:flutter/material.dart';
import 'package:wangcai_core/wangcai_core.dart';

extension TransactionCategoryUi on TransactionCategory {
  IconData get icon => iconDataFromKey(iconKey);
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
