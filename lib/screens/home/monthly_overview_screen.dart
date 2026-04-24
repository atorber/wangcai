import 'package:flutter/material.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class MonthlyOverviewScreen extends StatelessWidget {
  const MonthlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withOpacity(0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withOpacity(0.04),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDgoC8zhwG8f9w0bYLqstiA-UQ99TfYODhXGF82xqNVResOEaqYle0cEqiZocJSh8Am7AdeRY_Ug9_UWg-KT3ksMjG7Zq7qVo6JTwOuMFZX5nF93RsfvaEgMW6AoSs-ptXMozNYNOcaSj4Ts8U5eySYFg2A7pKmptDCK1Gu0OMSJBK3-phJ9ahv_RQ4i-DRBiZh94qMcFFfZq50eU6bvGug3DZPfPTwROPhVMM5Ad7is_7nhw30ZVkj21uw_4h35dj6uYYXw88s5en8',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '财务',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Consumer<TransactionProvider>(
          builder: (context, transactionProvider, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '9月概览',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              _buildOverviewCard(context, transactionProvider.transactions),
              const SizedBox(height: 32),
              _buildSpeedIndicator(context),
              const SizedBox(height: 32),
              _buildRecentActivity(context, transactionProvider.transactions),
              const SizedBox(height: 32),
              _buildGoalTracking(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, List<TransactionRecord> transactions) {
    final income = _monthlyTotal(transactions, isIncome: true);
    final expense = _monthlyTotal(transactions, isIncome: false);
    final totalAssets = income - expense;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '总资产',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${totalAssets.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceContainer),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本月收入',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+¥${income.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本月支出',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '-¥${expense.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '支出速度',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '正常',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
              ),
            ],
          ),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSpeedBar(0.5, AppColors.surfaceContainerHighest),
                const SizedBox(width: 4),
                _buildSpeedBar(0.66, AppColors.surfaceContainerHighest),
                const SizedBox(width: 4),
                _buildSpeedBar(1.0, AppColors.primaryContainer),
                const SizedBox(width: 4),
                _buildSpeedBar(0.75, AppColors.surfaceContainerHighest),
                const SizedBox(width: 4),
                _buildSpeedBar(0.5, AppColors.surfaceContainerHighest),
                const SizedBox(width: 4),
                _buildSpeedBar(0.66, AppColors.surfaceContainerHighest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedBar(double heightFactor, Color color) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<TransactionRecord> transactions) {
    final recentTransactions = transactions.take(4).toList(growable: false);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近交易',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 20,
                    color: AppColors.onSurface,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                '查看全部',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryContainer,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '暂无账单，点击底部“添加”开始记账',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        for (int i = 0; i < recentTransactions.length; i++) ...[
          _buildTransactionItem(
            context,
            icon: _iconForRecord(recentTransactions[i]),
            bgColor: recentTransactions[i].type == TransactionType.income
                ? AppColors.primaryFixed
                : AppColors.surfaceContainer,
            title: _titleForRecord(recentTransactions[i]),
            subtitle: _buildSubtitle(recentTransactions[i]),
            amount: _buildAmount(recentTransactions[i]),
            amountColor: recentTransactions[i].type == TransactionType.income
                ? AppColors.primaryContainer
                : AppColors.onSurface,
          ),
          if (i != recentTransactions.length - 1) _buildDivider(),
        ],
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64.0),
      child: Container(
        height: 0.5,
        color: AppColors.outlineVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildGoalTracking(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '储蓄目标',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 20,
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flight_takeoff, color: AppColors.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        '2024欧洲之旅',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    '¥3,200 / ¥5,000',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.64,
                backgroundColor: AppColors.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _monthlyTotal(List<TransactionRecord> transactions, {required bool isIncome}) {
    return transactions.fold(0, (sum, item) {
      final match = isIncome
          ? item.type == TransactionType.income || item.type == TransactionType.borrow
          : item.type == TransactionType.expense || item.type == TransactionType.lend;
      return match ? sum + item.amount : sum;
    });
  }

  String _buildAmount(TransactionRecord record) {
    final isIncome = record.type == TransactionType.income || record.type == TransactionType.borrow;
    final sign = isIncome ? '+' : '-';
    return '$sign¥${record.amount.toStringAsFixed(2)}';
  }

  String _buildSubtitle(TransactionRecord record) {
    final date = record.date;
    final datePart =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final accountPart = ' • ${record.accountName}';
    final relationPart = switch (record.type) {
      TransactionType.transfer =>
        ' • 转入${record.transferAccountName ?? '未选择账户'}',
      TransactionType.lend || TransactionType.borrow =>
        ' • ${record.lenderName ?? '未选择借贷人'}',
      _ => '',
    };
    final note = record.note.isNotEmpty ? ' • ${record.note}' : '';
    return '$datePart$accountPart$relationPart$note';
  }

  String _titleForRecord(TransactionRecord record) {
    switch (record.type) {
      case TransactionType.transfer:
        return '转账';
      case TransactionType.lend:
        return '借出';
      case TransactionType.borrow:
        return '借入';
      case TransactionType.expense:
      case TransactionType.income:
        return record.category;
    }
  }

  IconData _iconForRecord(TransactionRecord record) {
    switch (record.type) {
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.lend:
        return Icons.north_east;
      case TransactionType.borrow:
        return Icons.south_west;
      case TransactionType.expense:
      case TransactionType.income:
        return _iconForCategory(record.category);
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case '餐饮':
        return Icons.restaurant;
      case '交通':
        return Icons.directions_car;
      case '购物':
        return Icons.shopping_bag;
      case '电影':
        return Icons.confirmation_number;
      case '医疗':
        return Icons.medical_services;
      case '杂货':
        return Icons.local_grocery_store;
      case '账单':
        return Icons.bolt;
      default:
        return Icons.grid_view;
    }
  }
}
