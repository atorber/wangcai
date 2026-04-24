import 'package:finance_app/providers/security_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrivacyAmountText extends StatelessWidget {
  const PrivacyAmountText({
    super.key,
    required this.amount,
    this.prefix = '¥',
    this.sign,
    this.decimalDigits = 2,
    this.style,
  });

  final double amount;
  final String prefix;
  final String? sign;
  final int decimalDigits;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final privacyModeEnabled = context.select<SecurityProvider, bool>(
      (provider) => provider.privacyModeEnabled,
    );
    final symbol = sign ?? '';
    final text = privacyModeEnabled
        ? '$symbol$prefix****'
        : '$symbol$prefix${amount.toStringAsFixed(decimalDigits)}';
    return Text(text, style: style);
  }
}
