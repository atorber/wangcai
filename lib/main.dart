import 'package:flutter/material.dart';
import 'package:finance_app/theme/app_theme.dart';
import 'package:finance_app/screens/main_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
