import 'package:flutter/material.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initialRecord, this.onSaved});

  final TransactionRecord? initialRecord;
  final VoidCallback? onSaved;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _selectedTypeIndex = 0;
  int _selectedCategoryIndex = 0;
  String? _selectedAccountId;
  String? _selectedTransferAccountId;
  String? _selectedLenderId;
  DateTime _selectedDate = DateTime.now();
  final List<String> _transactionTypes = ['支出', '收入', '转账', '借出', '借入'];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _initializedFromRecord = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(_amountFocusNode);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = context.read<CategoryProvider>().categories;
    if (_selectedAccountId == null) {
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
        _selectedTransferAccountId = accounts.length > 1
            ? accounts[1].id
            : accounts.first.id;
      }
    }
    if (_selectedLenderId == null) {
      final lenders = context.read<AccountProvider>().lenders;
      if (lenders.isNotEmpty) {
        _selectedLenderId = lenders.first.id;
      }
    }
    if (!_initializedFromRecord && widget.initialRecord != null) {
      final record = widget.initialRecord!;
      _selectedTypeIndex = _indexFromType(record.type);
      _selectedAccountId = record.accountId;
      _selectedTransferAccountId = record.transferAccountId;
      _selectedLenderId = record.lenderId;
      _selectedDate = record.date;
      _amountController.text = record.amount.toStringAsFixed(2);
      _noteController.text = record.note;
      final categoryIndex = categories.indexWhere(
        (item) => item.label == record.category,
      );
      _selectedCategoryIndex = categoryIndex >= 0 ? categoryIndex : 0;
      _initializedFromRecord = true;
    }
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(
          alpha: 0.8,
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.secondary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          widget.initialRecord == null ? '添加账单' : '编辑账单',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryContainer,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeTabs(),
            const SizedBox(height: 32),
            _buildAmountInput(),
            const SizedBox(height: 32),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 32),
            _buildQuickSummaryCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppColors.primaryContainer.withValues(alpha: 0.15),
            ),
            child: Text(
              '保存',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_transactionTypes.length, (index) {
          final isSelected = _selectedTypeIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTypeIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      )
                    : null,
                child: Text(
                  _transactionTypes[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.onSurface
                        : AppColors.secondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        Text(
          '金额',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '¥',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.surfaceContainerHighest,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildQuickAmountButton('+10', () => _applyQuickAmount(10)),
            _buildQuickAmountButton('+50', () => _applyQuickAmount(50)),
            _buildQuickAmountButton('+100', () => _applyQuickAmount(100)),
            _buildQuickAmountButton('清零', _clearAmount),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.24)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = context.watch<CategoryProvider>().categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择类别',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer.withValues(alpha: 0.16)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryContainer)
                          : null,
                    ),
                    child: Icon(
                      cat.icon,
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    final isTransfer = _selectedTypeIndex == 2;
    final isLendOrBorrow = _selectedTypeIndex == 3 || _selectedTypeIndex == 4;
    final lenders = context.watch<AccountProvider>().lenders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailField(
          label: '日期',
          hint: _dateLabel,
          icon: Icons.calendar_today,
          readOnly: true,
          onTap: _pickDate,
        ),
        const SizedBox(height: 16),
        _buildDetailField(
          label: '备注',
          hint: '这是什么费用？',
          icon: Icons.edit_note,
          controller: _noteController,
        ),
        if (isTransfer) ...[
          const SizedBox(height: 16),
          _buildAccountSelectionCard(
            title: '转入账户',
            selectedAccountId: _selectedTransferAccountId,
            onTap: _pickTransferAccount,
          ),
        ],
        if (isLendOrBorrow) ...[
          const SizedBox(height: 16),
          _buildLenderPicker(lenders),
        ],
      ],
    );
  }

  Widget _buildAccountSelectionCard({
    required String title,
    required String? selectedAccountId,
    required VoidCallback onTap,
  }) {
    final accounts = context.watch<AccountProvider>().accounts;
    Account? selectedAccount;
    for (final account in accounts) {
      if (account.id == selectedAccountId) {
        selectedAccount = account;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.secondary),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedAccount?.name ?? '请选择账户',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLenderPicker(List<Lender> lenders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            '借贷人',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.secondary),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lenders.any((item) => item.id == _selectedLenderId)
                        ? _selectedLenderId
                        : (lenders.isNotEmpty ? lenders.first.id : null),
                    isExpanded: true,
                    hint: const Text('请选择借贷人'),
                    items: lenders
                        .map<DropdownMenuItem<String>>(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLenderId = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addLender,
              icon: const Icon(
                Icons.person_add_alt_1,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailField({
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.secondary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            readOnly: readOnly,
            onTap: onTap,
            controller: controller,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.outlineVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Icon(
                icon,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSummaryCard() {
    return _buildAccountSelectionCard(
      title: '付款账户',
      selectedAccountId: _selectedAccountId,
      onTap: _pickAccount,
    );
  }

  Account? _findSelectedAccount(List<Account> accounts) {
    for (final account in accounts) {
      if (account.id == _selectedAccountId) {
        return account;
      }
    }
    return accounts.isNotEmpty ? accounts.first : null;
  }

  Future<void> _pickAccount() async {
    final picked = await _selectAccount(allowCurrentAccount: true);
    if (picked != null) {
      setState(() {
        _selectedAccountId = picked;
      });
    }
  }

  Future<void> _pickTransferAccount() async {
    final picked = await _selectAccount(allowCurrentAccount: false);
    if (picked != null) {
      setState(() {
        _selectedTransferAccountId = picked;
      });
    }
  }

  Future<String?> _selectAccount({required bool allowCurrentAccount}) async {
    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加账户')));
      return null;
    }

    final availableAccounts = allowCurrentAccount
        ? accounts
        : accounts
              .where((item) => item.id != _selectedAccountId)
              .toList(growable: false);
    if (availableAccounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可选转入账户')));
      return null;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableAccounts.length,
          itemBuilder: (itemContext, index) {
            final account = availableAccounts[index];
            return ListTile(
              leading: Icon(account.icon, color: AppColors.primary),
              title: Text(account.name),
              subtitle: Text(account.typeLabel),
              trailing:
                  account.id ==
                      (allowCurrentAccount
                          ? _selectedAccountId
                          : _selectedTransferAccountId)
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(bottomSheetContext).pop(account.id),
            );
          },
        ),
      ),
    );
    return picked;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入大于 0 的金额')));
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();
    final categories = categoryProvider.categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置分类')));
      return;
    }
    final category =
        categories[_selectedCategoryIndex.clamp(0, categories.length - 1)]
            .label;
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final accounts = accountProvider.accounts;
    final selectedAccount = _findSelectedAccount(accounts);
    if (selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择付款账户')));
      return;
    }

    String? transferAccountId;
    String? transferAccountName;
    String? lenderId;
    String? lenderName;

    final type = _transactionTypeFromIndex(_selectedTypeIndex);
    if (type == TransactionType.transfer) {
      Account? transferAccount;
      for (final account in accounts) {
        if (account.id == _selectedTransferAccountId) {
          transferAccount = account;
          break;
        }
      }
      if (transferAccount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择转入账户')));
        return;
      }
      if (transferAccount.id == selectedAccount.id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('转入账户不能与转出账户相同')));
        return;
      }
      transferAccountId = transferAccount.id;
      transferAccountName = transferAccount.name;
    }

    if (type == TransactionType.lend || type == TransactionType.borrow) {
      final lenders = accountProvider.lenders;
      Lender? lender;
      for (final item in lenders) {
        if (item.id == _selectedLenderId) {
          lender = item;
          break;
        }
      }
      if (lender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择借贷人')));
        return;
      }
      lenderId = lender.id;
      lenderName = lender.name;
    }

    if (widget.initialRecord == null) {
      final record = await transactionProvider.addTransaction(
        type: type,
        amount: amount,
        category: category,
        accountId: selectedAccount.id,
        accountName: selectedAccount.name,
        transferAccountId: transferAccountId,
        transferAccountName: transferAccountName,
        lenderId: lenderId,
        lenderName: lenderName,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );
      await accountProvider.applyTransaction(record);
      await categoryProvider.markCategoryUsed(category);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账单已保存')));
        if (widget.onSaved != null) {
          widget.onSaved!();
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
          return;
        }
        _amountController.clear();
        _noteController.clear();
      }
      return;
    }

    final oldRecord = widget.initialRecord!;
    final updated = TransactionRecord(
      id: oldRecord.id,
      type: type,
      amount: amount,
      category: category,
      accountId: selectedAccount.id,
      accountName: selectedAccount.name,
      transferAccountId: transferAccountId,
      transferAccountName: transferAccountName,
      lenderId: lenderId,
      lenderName: lenderName,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );
    await accountProvider.applyTransactionUpdate(
      oldRecord: oldRecord,
      newRecord: updated,
    );
    await transactionProvider.updateTransaction(updated);
    await categoryProvider.markCategoryUsed(category);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _applyQuickAmount(double delta) {
    final raw = _amountController.text.trim();
    final current = double.tryParse(raw) ?? 0;
    final next = current + delta;
    _amountController.text = next.toStringAsFixed(2);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
  }

  void _clearAmount() {
    _amountController.clear();
  }

  Future<void> _addLender() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新增借贷人'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入姓名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    final accountProvider = context.read<AccountProvider>();
    await accountProvider.addLender(name);
    if (!mounted || accountProvider.lenders.isEmpty) {
      return;
    }
    final lender = accountProvider.lenders.lastWhere(
      (item) => item.name == name,
      orElse: () => accountProvider.lenders.first,
    );
    setState(() {
      _selectedLenderId = lender.id;
    });
  }

  TransactionType _transactionTypeFromIndex(int index) {
    switch (index) {
      case 0:
        return TransactionType.expense;
      case 1:
        return TransactionType.income;
      case 2:
        return TransactionType.transfer;
      case 3:
        return TransactionType.lend;
      case 4:
        return TransactionType.borrow;
      default:
        return TransactionType.expense;
    }
  }

  int _indexFromType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return 0;
      case TransactionType.income:
        return 1;
      case TransactionType.transfer:
        return 2;
      case TransactionType.lend:
        return 3;
      case TransactionType.borrow:
        return 4;
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return '今天';
    }
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }
}
