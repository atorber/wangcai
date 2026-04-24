import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _visibleCount = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '账单',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final records = provider.getTransactionsPage(offset: 0, limit: _visibleCount);
          final groupedRecords = _groupByMonth(records);
          if (records.isEmpty) {
            return Center(
              child: Text(
                '暂无账单记录',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groupedRecords.length + (records.length < provider.totalCount ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= groupedRecords.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final item = groupedRecords[index];
              if (item is String) {
                return _buildMonthHeader(context, item);
              }
              final record = item as TransactionRecord;
              return _buildBillItem(context, record);
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = parts[1];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        '$year年$month月',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildBillItem(BuildContext context, TransactionRecord record) {
    final isIncome = record.type == TransactionType.income || record.type == TransactionType.borrow;
    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            onPressed: (_) => _openEditPage(record),
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            icon: Icons.edit,
            label: '编辑',
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 8),
          SlidableAction(
            onPressed: (_) => _confirmDelete(record),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
            icon: Icons.delete_outline,
            label: '删除',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isIncome
                  ? AppColors.primaryFixed
                  : AppColors.surfaceContainerHighest,
              child: Icon(
                _iconForRecord(record),
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForRecord(record),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleForRecord(record),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}¥${record.amount.toStringAsFixed(2)}',
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

  Future<void> _confirmDelete(TransactionRecord record) async {
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
    if (confirmed == true && mounted) {
      await accountProvider.revertTransaction(record);
      await provider.deleteTransaction(record.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账单已删除')),
      );
    }
  }

  Future<void> _openEditPage(TransactionRecord record) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialRecord: record),
      ),
    );
    if (edited == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('账单已更新')),
      );
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels < threshold) {
      return;
    }
    final total = context.read<TransactionProvider>().totalCount;
    if (_visibleCount >= total) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    setState(() {
      _visibleCount += _pageSize;
      _isLoadingMore = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  String _subtitleForRecord(TransactionRecord record) {
    final datePart = _formatDate(record.date);
    switch (record.type) {
      case TransactionType.transfer:
        final toAccount = record.transferAccountName ?? '未选择转入账户';
        return '$datePart • ${record.accountName} -> $toAccount';
      case TransactionType.lend:
      case TransactionType.borrow:
        final lender = record.lenderName ?? '未选择借贷人';
        return '$datePart • ${record.accountName} • $lender';
      case TransactionType.expense:
      case TransactionType.income:
        return '$datePart • ${record.accountName}';
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

  List<Object> _groupByMonth(List<TransactionRecord> records) {
    final result = <Object>[];
    String? currentMonth;
    for (final record in records) {
      final monthKey =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      if (monthKey != currentMonth) {
        currentMonth = monthKey;
        result.add(monthKey);
      }
      result.add(record);
    }
    return result;
  }
}
