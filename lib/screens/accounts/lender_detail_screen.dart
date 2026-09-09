import 'package:flutter/material.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/cloud_ledger_bridge.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart'
    show CloudSyncException, LedgerException;

class LenderDetailScreen extends StatelessWidget {
  const LenderDetailScreen({super.key, required this.lender});

  final Lender lender;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, TransactionProvider>(
      builder: (context, accountProvider, transactionProvider, _) {
        Lender? current;
        for (final item in accountProvider.lenders) {
          if (item.id == lender.id) {
            current = item;
            break;
          }
        }
        if (current == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        final resolved = current;

        final related = transactionProvider.transactions
            .where((item) => item.lenderId == resolved.id)
            .toList(growable: false);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceContainerLowest.withValues(
              alpha: 0.9,
            ),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              '应收/应付详情',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: '删除',
                onPressed: () => _confirmDelete(context, resolved),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, resolved),
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
                  ...related.map((record) => _buildRecordItem(context, record)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Lender current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除应收/应付'),
        content: Text('确认删除「${current.name}」吗？有关联账单时无法删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await CloudLedgerBridge.mutate(
        context,
        action: (ledger) async {
          ledger.deleteLender(current.id);
        },
      );
    } on LedgerException catch (e) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'CONSTRAINT' ? '该应收/应付已有关联账单，无法删除' : e.message,
          ),
        ),
      );
      return;
    } on CloudSyncException catch (e) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
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
    messenger.showSnackBar(const SnackBar(content: Text('应收/应付已删除')));
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildHeader(BuildContext context, Lender current) {
    final isReceivable = current.balance > 0;
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
            current.name,
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: AppColors.onSurface),
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
            amount: current.balance.abs(),
            prefix: '¥ ',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: isReceivable
                  ? AppColors.primaryContainer
                  : AppColors.tertiary,
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
        '当前暂无关联账单',
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
    double totalBorrow = 0;
    double totalLend = 0;
    final monthlyNet = <String, double>{};
    for (final item in related) {
      final amount = item.type == TransactionType.borrow
          ? -item.amount
          : item.amount;
      if (item.type == TransactionType.borrow) {
        totalBorrow += item.amount;
      } else {
        totalLend += item.amount;
      }
      final monthKey =
          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}';
      monthlyNet[monthKey] = (monthlyNet[monthKey] ?? 0) + amount;
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
                title: '累计借出',
                amount: totalLend,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: '累计借入',
                amount: totalBorrow,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
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
                '月度净往来趋势',
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
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
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, TransactionRecord record) {
    final isBorrow = record.type == TransactionType.borrow;
    final actionLabel = isBorrow ? '借入' : '借出';
    final amountColor = isBorrow
        ? AppColors.primaryContainer
        : AppColors.onSurface;
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
                  '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')} ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')} • ${transactionClientLabel(record.client)} • ${record.note.isEmpty ? '无备注' : record.note}',
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
