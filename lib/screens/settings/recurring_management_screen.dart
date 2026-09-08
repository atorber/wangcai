import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/recurring_rule.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/recurring_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecurringManagementScreen extends StatelessWidget {
  const RecurringManagementScreen({super.key});

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
          '周期账单',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: '新增规则',
          ),
        ],
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, _) {
          final rules = provider.rules;
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '暂无周期账单\n可添加房租、水电、工资等固定收支',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final isIncome = rule.type == TransactionType.income;
              return InkWell(
                onTap: () => _openEditor(context, existing: rule),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isIncome
                            ? AppColors.primaryFixed
                            : AppColors.surfaceContainerHighest,
                        child: Icon(
                          isIncome ? Icons.south_west : Icons.north_east,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rule.frequencyLabel} · ${rule.category} · ${rule.accountName}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            Text(
                              '下次：${_formatDate(rule.nextRunDate)}${rule.enabled ? '' : ' · 已停用'}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}¥${rule.amount.toStringAsFixed(2)}',
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
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    RecurringRule? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecurringEditorSheet(existing: existing),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _RecurringEditorSheet extends StatefulWidget {
  const _RecurringEditorSheet({this.existing});

  final RecurringRule? existing;

  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late RecurringFrequency _frequency;
  late int _dayOfMonth;
  late int _weekday;
  late bool _enabled;
  String? _accountId;
  String? _category;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? TransactionType.expense;
    _frequency = existing?.frequency ?? RecurringFrequency.monthly;
    _dayOfMonth = existing?.dayOfMonth ?? DateTime.now().day.clamp(1, 28);
    _weekday = existing?.weekday ?? DateTime.now().weekday;
    _enabled = existing?.enabled ?? true;
    _accountId = existing?.accountId;
    _category = existing?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final categories = context.watch<CategoryProvider>().categories;
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }
    if (_category == null && categories.isNotEmpty) {
      _category = categories.first.label;
    }
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? '新增周期账单' : '编辑周期账单',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：房租',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '金额'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('支出'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('收入'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
                decoration: const InputDecoration(labelText: '类型'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.any((item) => item.label == _category)
                    ? _category
                    : (categories.isNotEmpty ? categories.first.label : null),
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.label,
                        child: Text(item.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: accounts.any((item) => item.id == _accountId)
                    ? _accountId
                    : (accounts.isNotEmpty ? accounts.first.id : null),
                items: accounts
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _accountId = value);
                  }
                },
                decoration: const InputDecoration(labelText: '账户'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _frequency,
                items: const [
                  DropdownMenuItem(
                    value: RecurringFrequency.monthly,
                    child: Text('每月'),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.weekly,
                    child: Text('每周'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                  }
                },
                decoration: const InputDecoration(labelText: '周期'),
              ),
              const SizedBox(height: 12),
              if (_frequency == RecurringFrequency.monthly)
                DropdownButtonFormField<int>(
                  initialValue: _dayOfMonth,
                  items: List.generate(
                    28,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('每月 ${index + 1} 日'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dayOfMonth = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: '执行日'),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  items: const [
                    DropdownMenuItem(value: DateTime.monday, child: Text('周一')),
                    DropdownMenuItem(
                      value: DateTime.tuesday,
                      child: Text('周二'),
                    ),
                    DropdownMenuItem(
                      value: DateTime.wednesday,
                      child: Text('周三'),
                    ),
                    DropdownMenuItem(
                      value: DateTime.thursday,
                      child: Text('周四'),
                    ),
                    DropdownMenuItem(value: DateTime.friday, child: Text('周五')),
                    DropdownMenuItem(
                      value: DateTime.saturday,
                      child: Text('周六'),
                    ),
                    DropdownMenuItem(value: DateTime.sunday, child: Text('周日')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _weekday = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: '执行日'),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.existing != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await context.read<RecurringProvider>().removeRule(
                            widget.existing!.id,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('删除'),
                      ),
                    ),
                  if (widget.existing != null) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _save(accounts),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(List<Account> accounts) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入名称')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入大于 0 的金额')));
      return;
    }
    if (_accountId == null || _category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择账户和分类')));
      return;
    }
    Account? account;
    for (final item in accounts) {
      if (item.id == _accountId) {
        account = item;
        break;
      }
    }
    if (account == null) {
      return;
    }

    final provider = context.read<RecurringProvider>();
    final start = DateTime.now();
    final existing = widget.existing;
    final scheduleChanged =
        existing != null &&
        (existing.frequency != _frequency ||
            existing.dayOfMonth != _dayOfMonth ||
            existing.weekday != _weekday);
    final nextRunDate = (existing == null || scheduleChanged)
        ? provider.computeInitialNextRun(
            frequency: _frequency,
            startDate: start,
            dayOfMonth: _dayOfMonth,
            weekday: _weekday,
          )
        : existing.nextRunDate;
    final rule = RecurringRule(
      id: existing?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      type: _type,
      amount: amount,
      category: _category!,
      accountId: account.id,
      accountName: account.name,
      frequency: _frequency,
      dayOfMonth: _dayOfMonth,
      weekday: _weekday,
      startDate: existing?.startDate ?? start,
      nextRunDate: nextRunDate,
      enabled: _enabled,
      note: _noteController.text.trim(),
    );
    await provider.upsertRule(rule);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
