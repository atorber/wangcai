import 'package:flutter/material.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';

class LenderDetailScreen extends StatelessWidget {
  const LenderDetailScreen({
    super.key,
    required this.lender,
  });

  final Lender lender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '借贷人详情',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          final related = transactionProvider.transactions
              .where((item) => item.lenderId == lender.id)
              .toList(growable: false);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                Text(
                  '关联账单',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                if (related.isEmpty)
                  _buildEmpty(context)
                else
                  ...related.map((record) => _buildRecordItem(context, record)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isReceivable = lender.balance > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lender.name,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            isReceivable ? '当前应收' : '当前应付',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          PrivacyAmountText(
            amount: lender.balance.abs(),
            prefix: '¥ ',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: isReceivable ? AppColors.primaryContainer : AppColors.tertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '当前借贷人暂无关联账单',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, TransactionRecord record) {
    final isBorrow = record.type == TransactionType.borrow;
    final actionLabel = isBorrow ? '借入' : '借出';
    final amountColor = isBorrow ? AppColors.primaryContainer : AppColors.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$actionLabel • ${record.accountName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')} ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')} • ${record.note.isEmpty ? '无备注' : record.note}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrivacyAmountText(
            amount: record.amount,
            sign: isBorrow ? '-' : '+',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
