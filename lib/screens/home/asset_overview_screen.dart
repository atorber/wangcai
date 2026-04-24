import 'package:flutter/material.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/models/lender.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/screens/accounts/account_detail_screen.dart';
import 'package:finance_app/screens/accounts/lender_detail_screen.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:finance_app/screens/accounts/add_account_screen.dart' as finance_add_account;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class AssetOverviewScreen extends StatelessWidget {
  const AssetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        centerTitle: true,
        title: Text(
          '资产概览',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primaryContainer),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<AccountProvider>(
          builder: (context, accountProvider, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalAssetsCard(context, accountProvider),
              const SizedBox(height: 24),
              Text(
                '我的账户',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              _buildAccountGrid(context, accountProvider.accounts),
              const SizedBox(height: 24),
              Text(
                '借贷人',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              _buildLenderGrid(context, accountProvider.lenders),
              const SizedBox(height: 24),
              _buildAddAccountButton(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard(BuildContext context, AccountProvider accountProvider) {
    return Container(
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
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总资产',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '¥',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(width: 4),
                    PrivacyAmountText(
                      amount: accountProvider.totalAssets,
                      prefix: '',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '净资产',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            PrivacyAmountText(
                              amount: accountProvider.netAssets,
                              prefix: '¥ ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '总负债',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            PrivacyAmountText(
                              amount: accountProvider.totalLiabilities,
                              prefix: '¥ ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.tertiary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAccountGrid(BuildContext context, List<Account> accounts) {
    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '暂无账户，点击下方按钮添加',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.5 : 2.0,
          children: accounts
              .map((account) => _buildAccountCard(context, account))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildLenderGrid(BuildContext context, List<Lender> lenders) {
    if (lenders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '暂无借贷人',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.5 : 2.0,
          children: lenders
              .map<Widget>((lender) => _buildLenderCard(context, lender))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildLenderCard(BuildContext context, Lender lender) {
    final isReceivable = lender.balance > 0;
    final card = InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LenderDetailScreen(lender: lender),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lender.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isReceivable ? '应收' : '应付',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                PrivacyAmountText(
                  amount: lender.balance.abs(),
                  prefix: '¥ ',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: isReceivable ? AppColors.primaryContainer : AppColors.tertiary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Slidable(
      key: ValueKey('lender-${lender.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.24,
        children: [
          SlidableAction(
            onPressed: (_) => _showEditLenderDialog(context, lender),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: '编辑',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    final colorConfig = _colorForType(account.type);
    return _buildBaseAccountCard(
      context,
      icon: account.icon,
      iconColor: colorConfig.$1,
      iconBgColor: colorConfig.$2,
      title: account.typeLabel,
      subtitle: account.name,
      balanceLabel: account.isLiability ? '负债' : '余额',
      balanceAmount: account.balance,
      balanceColor: account.isLiability ? AppColors.tertiary : AppColors.onSurface,
      tag: account.subtitle.isNotEmpty ? account.subtitle : null,
      onEdit: () => _showEditAccountDialog(context, account),
      onDelete: () => _showDeleteDialog(context, account),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: account),
        ),
      ),
    );
  }

  Widget _buildBaseAccountCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    String? tag,
    required String balanceLabel,
    required double balanceAmount,
    Color balanceColor = AppColors.onSurface,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    Widget? extraWidget,
  }) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurface,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.onPrimaryFixed,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balanceLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                PrivacyAmountText(
                  amount: balanceAmount,
                  prefix: '¥ ',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: balanceColor,
                      ),
                ),
              ],
            ),
            if (extraWidget != null) extraWidget,
          ],
        ),
      ),
    );
    if (onEdit == null && onDelete == null) {
      return card;
    }
    final actionCount = (onEdit != null ? 1 : 0) + (onDelete != null ? 1 : 0);
    return Slidable(
      key: ValueKey('$title-$subtitle'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: actionCount * 0.24,
        children: [
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: '编辑',
              borderRadius: BorderRadius.circular(12),
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: '删除',
              borderRadius: BorderRadius.circular(12),
            ),
        ],
      ),
      child: card,
    );
  }

  Widget _buildAddAccountButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const finance_add_account.AddAccountScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              '添加账户',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _colorForType(AccountType type) {
    switch (type) {
      case AccountType.debitCard:
        return (AppColors.primary, AppColors.primary.withValues(alpha: 0.1));
      case AccountType.creditCard:
        return (AppColors.tertiary, AppColors.tertiary.withValues(alpha: 0.1));
      case AccountType.alipay:
        return (const Color(0xFF1677FF), const Color(0xFF1677FF).withValues(alpha: 0.1));
      case AccountType.wechatPay:
        return (const Color(0xFF07C160), const Color(0xFF07C160).withValues(alpha: 0.1));
      case AccountType.cash:
        return (AppColors.onSurface, AppColors.surfaceVariant);
      case AccountType.other:
        return (AppColors.secondary, AppColors.surfaceContainer);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确认删除「${account.name}」吗？'),
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

    if (shouldDelete == true && context.mounted) {
      final removed = context.read<AccountProvider>().removeAccount(
            account.id,
            relatedTransactions: context.read<TransactionProvider>().transactions,
          );
      if (!removed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该账户已有关联账单，无法删除')),
        );
      }
    }
  }

  Future<void> _showEditAccountDialog(BuildContext context, Account account) async {
    var nameValue = account.name;
    var balanceValue = account.balance.toStringAsFixed(2);
    bool shouldCreateAdjustment = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('编辑账户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: nameValue,
                  onChanged: (value) => nameValue = value,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '账户名称',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: balanceValue,
                  onChanged: (value) => balanceValue = value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '账户余额',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: shouldCreateAdjustment,
                  onChanged: (value) {
                    setDialogState(() {
                      shouldCreateAdjustment = value ?? false;
                    });
                  },
                  title: const Text('将差额补记为收支'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final name = nameValue.trim();
    final balance = double.tryParse(balanceValue.trim());

    if (name.isEmpty || balance == null) {
      messenger.showSnackBar(const SnackBar(content: Text('请输入合法名称和余额')));
      return;
    }

    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final previousBalance = account.balance;

    await accountProvider.updateAccount(
      id: account.id,
      name: name,
      balance: shouldCreateAdjustment ? previousBalance : balance,
    );

    if (shouldCreateAdjustment) {
      final delta = balance - previousBalance;
      if (delta != 0) {
        final isIncome = delta > 0;
        final record = await transactionProvider.addTransaction(
          type: isIncome ? TransactionType.income : TransactionType.expense,
          amount: delta.abs(),
          category: '余额调整',
          accountId: account.id,
          accountName: name,
          date: DateTime.now(),
          note: '编辑账户余额补记',
        );
        await accountProvider.applyTransaction(record);
      }
    }

    if (context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('账户已更新')));
    }
  }

  Future<void> _showEditLenderDialog(BuildContext context, Lender lender) async {
    var nameValue = lender.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑借贷人'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nameValue,
                onChanged: (value) => nameValue = value,
                autofocus: true,
                decoration: const InputDecoration(labelText: '借贷人名称'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: lender.balance.toStringAsFixed(2),
                readOnly: true,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: '往来余额',
                  helperText: '余额不可直接编辑，请通过借出/借入账单自动调整',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final name = nameValue.trim();

    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请输入合法借贷人名称')));
      return;
    }

    await context.read<AccountProvider>().updateLender(
          id: lender.id,
          name: name,
          balance: lender.balance,
        );
    if (context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('借贷人已更新')));
    }
  }
}
