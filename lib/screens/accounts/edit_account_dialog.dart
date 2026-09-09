import 'package:flutter/material.dart';
import 'package:finance_app/models/account.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/services/cloud_ledger_bridge.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart'
    show CloudSyncException, TransactionClient;

/// 编辑账户（含余额）。可勾选将差额补记为收入/支出。
Future<bool> showEditAccountDialog(
  BuildContext context, {
  required Account account,
}) async {
  var nameValue = account.name;
  var balanceValue = account.balance.toStringAsFixed(2);
  var creditLimitValue = account.creditLimit?.toStringAsFixed(2) ?? '';
  var billingDay = account.billingDay ?? 1;
  var paymentDay = account.paymentDay ?? 20;
  var recordDifference = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final parsedBalance = double.tryParse(balanceValue.trim());
        final delta = parsedBalance == null
            ? null
            : parsedBalance - account.balance;
        final showDeltaHint =
            recordDifference && delta != null && delta.abs() > 0.000001;

        return AlertDialog(
          title: const Text('编辑账户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: nameValue,
                  onChanged: (value) => nameValue = value,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '账户名称'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: balanceValue,
                  onChanged: (value) {
                    setDialogState(() => balanceValue = value);
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: account.isCreditCard ? '账户余额（负债为负）' : '账户余额',
                    helperText:
                        '当前 ¥${account.balance.toStringAsFixed(2)}',
                  ),
                ),
                if (account.isCreditCard) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: creditLimitValue,
                    onChanged: (value) => creditLimitValue = value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: '信用额度'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: billingDay,
                    items: List.generate(
                      28,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('账单日 ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => billingDay = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: '账单日'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: paymentDay,
                    items: List.generate(
                      28,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('还款日 ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => paymentDay = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: '还款日'),
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: recordDifference,
                  onChanged: (value) {
                    setDialogState(() {
                      recordDifference = value ?? false;
                    });
                  },
                  title: const Text('将差额补记为收支'),
                  subtitle: Text(
                    showDeltaHint
                        ? '将记一笔${delta > 0 ? '收入' : '支出'} ¥${delta.abs().toStringAsFixed(2)}'
                        : '勾选后按「新余额 − 原余额」自动生成记账',
                    style: Theme.of(dialogContext).textTheme.labelSmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
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
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed != true || !context.mounted) {
    return false;
  }

  final messenger = ScaffoldMessenger.of(context);
  final name = nameValue.trim();
  final balance = double.tryParse(balanceValue.trim());
  final creditLimitText = creditLimitValue.trim();
  final creditLimit = creditLimitText.isEmpty
      ? null
      : double.tryParse(creditLimitText);

  if (name.isEmpty || balance == null) {
    messenger.showSnackBar(const SnackBar(content: Text('请输入合法名称和余额')));
    return false;
  }
  if (account.isCreditCard &&
      creditLimitText.isNotEmpty &&
      creditLimit == null) {
    messenger.showSnackBar(const SnackBar(content: Text('请输入合法信用额度')));
    return false;
  }

  try {
    await CloudLedgerBridge.mutate(
      context,
      action: (ledger) async {
        ledger.updateAccount(
          id: account.id,
          name: name,
          balance: balance,
          creditLimit: account.isCreditCard ? creditLimit : null,
          billingDay: account.isCreditCard ? billingDay : null,
          paymentDay: account.isCreditCard ? paymentDay : null,
          recordBalanceDifference: recordDifference,
          client: TransactionClient.app,
        );
      },
    );
  } on CloudSyncException catch (e) {
    if (!context.mounted) {
      return false;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'LOCK_BUSY' ? '云端账本正被其他端写入，请稍后重试' : '更新失败：$e',
        ),
      ),
    );
    return false;
  }

  // 确保本地 Provider 已是最新（mutate 会回写）
  if (context.mounted) {
    context.read<AccountProvider>();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          recordDifference && balance != account.balance
              ? '账户已更新，并已补记差额'
              : '账户已更新',
        ),
      ),
    );
  }
  return true;
}
