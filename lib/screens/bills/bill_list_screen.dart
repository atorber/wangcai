import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _keywordController = TextEditingController();
  static const int _pageSize = 20;
  int _visibleCount = 20;
  bool _isLoadingMore = false;
  int _selectedTypeIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  static const List<String> _typeFilters = ['全部', '支出', '收入', '转账', '借贷'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
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
          final filter = _buildFilter();
          final records = provider.queryPage(
            offset: 0,
            limit: _visibleCount,
            filter: filter,
          );
          final total = provider.countByFilter(filter);
          final groupedRecords = _groupByMonth(records);
          if (records.isEmpty) {
            return Column(
              children: [
                _buildFilterSection(context),
                Expanded(
                  child: Center(
                    child: Text(
                      '暂无账单记录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildFilterSection(context),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount:
                      groupedRecords.length + (records.length < total ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= groupedRecords.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final item = groupedRecords[index];
                    if (item is String) {
                      return _buildMonthHeader(context, item);
                    }
                    final record = item as TransactionRecord;
                    return _buildBillItem(context, record);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_typeFilters.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _typeFilters.length - 1 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(_typeFilters[index]),
                    selected: _selectedTypeIndex == index,
                    onSelected: (_) {
                      setState(() {
                        _selectedTypeIndex = index;
                        _visibleCount = _pageSize;
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRangeLabel,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _visibleCount = _pageSize;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: '清除日期',
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: '搜索分类、账户、备注',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _keywordController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _keywordController.clear();
                        setState(() {
                          _visibleCount = _pageSize;
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
            onChanged: (_) {
              setState(() {
                _visibleCount = _pageSize;
              });
            },
          ),
        ],
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
    final isIncome =
        record.type == TransactionType.income ||
        record.type == TransactionType.borrow;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账单已删除')));
    }
  }

  Future<void> _openEditPage(TransactionRecord record) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialRecord: record),
      ),
    );
    if (edited == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账单已更新')));
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
    final total = context.read<TransactionProvider>().countByFilter(
      _buildFilter(),
    );
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
        999,
      );
      _visibleCount = _pageSize;
    });
  }

  TransactionQueryFilter _buildFilter() {
    final keyword = _keywordController.text.trim();
    return TransactionQueryFilter(
      types: _typesForFilter(),
      startDate: _startDate,
      endDate: _endDate,
      keyword: keyword.isEmpty ? null : keyword,
    );
  }

  Set<TransactionType>? _typesForFilter() {
    switch (_selectedTypeIndex) {
      case 1:
        return {TransactionType.expense};
      case 2:
        return {TransactionType.income};
      case 3:
        return {TransactionType.transfer};
      case 4:
        return {TransactionType.lend, TransactionType.borrow};
      default:
        return null;
    }
  }

  String get _dateRangeLabel {
    if (_startDate == null || _endDate == null) {
      return '日期范围：全部';
    }
    return '${_shortDate(_startDate!)} - ${_shortDate(_endDate!)}';
  }

  String _shortDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
