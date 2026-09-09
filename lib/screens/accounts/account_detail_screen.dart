import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/screens/accounts/edit_account_dialog.dart';
import 'package:finance_app/services/cloud_ledger_bridge.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart' show CloudSyncException;

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accountProvider, transactionProvider, _) {
        final account = accountProvider.accounts.firstWhere(
          (item) => item.id == this.account.id,
          orElse: () => this.account,
        );
        final related = transactionProvider.transactions
            .where((item) {
              return item.accountId == account.id ||
                  item.transferAccountId == account.id;
            })
            .toList(growable: false);
        final grouped = _groupRecords(related);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceContainerLowest.withValues(
              alpha: 0.9,
            ),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              '账户详情',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: '编辑账户',
                onPressed: () =>
                    showEditAccountDialog(context, account: account),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, account),
                const SizedBox(height: 24),
                _buildStatsSection(context, related),
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Account account) {
    return InkWell(
      onTap: () => showEditAccountDialog(context, account: account),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
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
            '当前余额（点按可编辑）',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          PrivacyAmountText(
            amount: account.balance,
            prefix: '¥ ',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: account.balance >= 0
                  ? AppColors.primary
                  : AppColors.tertiary,
            ),
          ),
          if (account.isCreditCard) ...[
            const SizedBox(height: 16),
            Text(
              [
                if (account.creditLimit != null)
                  '额度 ¥${account.creditLimit!.toStringAsFixed(0)}',
                if (account.availableCredit != null)
                  '可用 ¥${account.availableCredit!.toStringAsFixed(0)}',
                if (account.billingDay != null) '账单日 ${account.billingDay}',
                if (account.paymentDay != null) '还款日 ${account.paymentDay}',
              ].join(' · '),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    List<TransactionRecord> related,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    final monthlyNet = <String, double>{};
    for (final item in related) {
      final monthKey =
          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}';
      final amount = _signedAmountForAccount(item);
      monthlyNet[monthKey] = (monthlyNet[monthKey] ?? 0) + amount;
      if (amount >= 0) {
        totalIncome += amount;
      } else {
        totalExpense += amount.abs();
      }
    }

    final trend = monthlyNet.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final recentTwo = trend.length <= 2
        ? trend
        : trend.sublist(trend.length - 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '统计概览',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '累计收入',
                amount: totalIncome,
                amountColor: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '累计支出',
                amount: totalExpense,
                amountColor: AppColors.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTrendCard(context, recentTwo),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          PrivacyAmountText(
            amount: amount,
            prefix: '¥ ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    List<MapEntry<String, double>> recentTwo,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '月度净流入趋势',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (recentTwo.isEmpty)
            Text(
              '暂无数据',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            ...recentTwo.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    PrivacyAmountText(
                      amount: entry.value.abs(),
                      sign: entry.value >= 0 ? '+' : '-',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: entry.value >= 0
                            ? AppColors.primaryContainer
                            : AppColors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, TransactionRecord record) {
    final isIncome =
        record.type == TransactionType.income ||
        record.type == TransactionType.borrow;
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
                color: isIncome
                    ? AppColors.primaryContainer
                    : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionRecord record,
  ) async {
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
    try {
      await CloudLedgerBridge.mutate(
        context,
        action: (ledger) async {
          ledger.deleteTransaction(record.id);
        },
      );
    } on CloudSyncException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'LOCK_BUSY' ? '云端账本正被其他端写入，请稍后重试' : '删除失败：$e',
          ),
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('账单已删除')));
  }

  Future<void> _openEditPage(
    BuildContext context,
    TransactionRecord record,
  ) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialRecord: record),
      ),
    );
    if (edited == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账单已更新')));
    }
  }

  Map<String, List<TransactionRecord>> _groupRecords(
    List<TransactionRecord> records,
  ) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

    final grouped = <String, List<TransactionRecord>>{
      '今天': [],
      '近7天': [],
      '更早': [],
    };

    for (final record in records) {
      final date = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
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
      widgets.addAll(
        records.map((record) => _buildRecordItem(context, record)),
      );
    }
    return widgets;
  }

  double _signedAmountForAccount(TransactionRecord record) {
    if (record.type == TransactionType.income ||
        record.type == TransactionType.borrow) {
      return record.amount;
    }
    if (record.type == TransactionType.transfer) {
      if (record.accountId == account.id) {
        return -record.amount;
      }
      if (record.transferAccountId == account.id) {
        return record.amount;
      }
    }
    return -record.amount;
  }
}
