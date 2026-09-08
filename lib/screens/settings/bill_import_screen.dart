import 'package:file_selector/file_selector.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/bill_import_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BillImportScreen extends StatefulWidget {
  const BillImportScreen({super.key});

  @override
  State<BillImportScreen> createState() => _BillImportScreenState();
}

class _BillImportScreenState extends State<BillImportScreen> {
  BillImportResult? _result;
  String? _selectedAccountId;
  bool _importing = false;
  final Set<int> _selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '导入账单',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '支持支付宝 / 微信导出的 CSV 账单。导入后会写入所选账户，并按关键词建议分类。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      accounts.any((item) => item.id == _selectedAccountId)
                      ? _selectedAccountId
                      : null,
                  items: accounts
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _selectedAccountId = value);
                  },
                  decoration: const InputDecoration(labelText: '导入到账户'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickAndParse,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('选择 CSV'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canImport ? _confirmImport : null,
                        child: Text(_importing ? '导入中...' : '确认导入'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _result!.hasError
                      ? _result!.errorMessage!
                      : '识别到 ${_sourceLabel(_result!.source)} · 共 ${_result!.rows.length} 条（已选 ${_selectedIndexes.length}）',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _result!.hasError
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (!_result!.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndexes
                            ..clear()
                            ..addAll(
                              List.generate(_result!.rows.length, (i) => i),
                            );
                        });
                      },
                      child: const Text('全选'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selectedIndexes.clear),
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ),
          ],
          Expanded(
            child: _result == null || _result!.hasError
                ? Center(
                    child: Text(
                      '请先选择账单文件',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _result!.rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final row = _result!.rows[index];
                      final selected = _selectedIndexes.contains(index);
                      final isIncome = row.type == TransactionType.income;
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIndexes.add(index);
                            } else {
                              _selectedIndexes.remove(index);
                            }
                          });
                        },
                        tileColor: AppColors.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          '${row.suggestedCategory} · ${row.counterparty.isEmpty ? '未知对方' : row.counterparty}',
                        ),
                        subtitle: Text(
                          '${_formatDate(row.date)} · ${row.note.isEmpty ? row.rawCategory : row.note}',
                        ),
                        secondary: Text(
                          '${isIncome ? '+' : '-'}¥${row.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isIncome
                                ? AppColors.primaryContainer
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool get _canImport =>
      !_importing &&
      _result != null &&
      !_result!.hasError &&
      _selectedIndexes.isNotEmpty &&
      _selectedAccountId != null;

  Future<void> _pickAndParse() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'csv', extensions: ['csv', 'txt']),
      ],
    );
    if (file == null) {
      return;
    }
    final text = await file.readAsString();
    final result = BillImportService.parseCsv(text);
    setState(() {
      _result = result;
      _selectedIndexes
        ..clear()
        ..addAll(
          result.hasError
              ? const <int>{}
              : List.generate(result.rows.length, (i) => i),
        );
    });
  }

  Future<void> _confirmImport() async {
    if (!_canImport) {
      return;
    }
    final accounts = context.read<AccountProvider>().accounts;
    Account? account;
    for (final item in accounts) {
      if (item.id == _selectedAccountId) {
        account = item;
        break;
      }
    }
    if (account == null) {
      return;
    }

    setState(() => _importing = true);
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    var count = 0;
    try {
      final indexes = _selectedIndexes.toList()..sort();
      for (final index in indexes) {
        final row = _result!.rows[index];
        final record = await transactionProvider.addTransaction(
          type: row.type,
          amount: row.amount,
          category: row.suggestedCategory,
          accountId: account.id,
          accountName: account.name,
          date: row.date,
          note: row.note,
        );
        await accountProvider.applyTransaction(record);
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入 $count 条账单')));
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  String _sourceLabel(BillImportSource source) {
    switch (source) {
      case BillImportSource.alipay:
        return '支付宝';
      case BillImportSource.wechat:
        return '微信';
      case BillImportSource.unknown:
        return '未知来源';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
