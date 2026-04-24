import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '账户详情',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          final related = transactionProvider.transactions.where((item) {
            return item.accountId == account.id || item.transferAccountId == account.id;
          }).toList(growable: false);
          final grouped = _groupRecords(related);

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
                  ..._buildGroupedRecords(context, grouped),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            account.name,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            account.typeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            '当前余额',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          PrivacyAmountText(
            amount: account.balance,
            prefix: '¥ ',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: account.balance >= 0 ? AppColors.primary : AppColors.tertiary,
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
        '当前账户暂无关联账单',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, TransactionRecord record) {
    final isIncome = record.type == TransactionType.income || record.type == TransactionType.borrow;
    return Slidable(
      key: ValueKey('account-detail-${record.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            onPressed: (_) => _openEditPage(context, record),
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            icon: Icons.edit,
            label: '编辑',
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 8),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, record),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
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
                    record.category,
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
              sign: isIncome ? '+' : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isIncome ? AppColors.primaryContainer : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionRecord record) async {
    final provider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账单'),
        content: const Text('确认删除这条账单记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await accountProvider.revertTransaction(record);
    await provider.deleteTransaction(record.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('账单已删除')),
    );
  }

  Future<void> _openEditPage(BuildContext context, TransactionRecord record) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialRecord: record),
      ),
    );
    if (edited == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账单已更新')),
      );
    }
  }

  Map<String, List<TransactionRecord>> _groupRecords(List<TransactionRecord> records) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

    final grouped = <String, List<TransactionRecord>>{
      '今天': [],
      '近7天': [],
      '更早': [],
    };

    for (final record in records) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      if (date == todayStart) {
        grouped['今天']!.add(record);
      } else if (!date.isBefore(sevenDaysAgo) && date.isBefore(todayStart)) {
        grouped['近7天']!.add(record);
      } else {
        grouped['更早']!.add(record);
      }
    }
    return grouped;
  }

  List<Widget> _buildGroupedRecords(
    BuildContext context,
    Map<String, List<TransactionRecord>> grouped,
  ) {
    final widgets = <Widget>[];
    const order = ['今天', '近7天', '更早'];
    for (final section in order) {
      final records = grouped[section] ?? const [];
      if (records.isEmpty) {
        continue;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            section,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ),
      );
      widgets.addAll(records.map((record) => _buildRecordItem(context, record)));
    }
    return widgets;
  }
}
