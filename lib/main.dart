import 'package:flutter/material.dart';
import 'package:finance_app/providers/app_settings_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/security_provider.dart';
import 'package:finance_app/theme/app_theme.dart';
import 'package:finance_app/screens/main_layout.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/widgets/app_lock_gate.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: '旺财',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const AppLockGate(child: MainLayout()),
        ),
      ),
    );
  }
}
