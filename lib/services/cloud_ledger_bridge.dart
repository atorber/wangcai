import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/budget_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/recurring_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/cloud_sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart';

/// 将 Provider 快照与 [Ledger]/[SyncClient] 打通。
/// 已配置云同步时：加锁 → 按 revision 对齐底稿 → 变更 → 推送 → 回写 Provider。
/// 未配置时：仅本地变更并更新 local revision。
class CloudLedgerBridge {
  const CloudLedgerBridge._();

  static Future<T> mutate<T>(
    BuildContext context, {
    required Future<T> Function(Ledger ledger) action,
  }) async {
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final recurringProvider = context.read<RecurringProvider>();

    final localRevision = await CloudSyncService.getLocalRevision();
    final deviceId = await CloudSyncService.getOrCreateDeviceId();
    final ledger = Ledger(
      LedgerBundle(
        version: 1,
        schemaVersion: LedgerBundle.currentSchemaVersion,
        revision: localRevision,
        deviceId: deviceId,
        exportedAt: DateTime.now(),
        accounts: accountProvider.accounts,
        lenders: accountProvider.lenders,
        categories: categoryProvider.categories,
        transactions: transactionProvider.transactions,
        budgets: budgetProvider.budgets,
        recurringRules: recurringProvider.rules,
      ),
    );

    final config = await CloudSyncService.loadConfig();
    late final T result;
    if (config != null && CloudSyncService.isSupportedOnCurrentPlatform) {
      final client = await CloudSyncService.createSyncClient(config);
      result = await client.writeTransaction(ledger, action);
      await CloudSyncService.setLocalRevision(ledger.revision);
      await CloudSyncService.markSyncNow();
    } else {
      result = await action(ledger);
      ledger.bumpRevision(deviceId: deviceId);
      await CloudSyncService.setLocalRevision(ledger.revision);
    }

    await _applyBundle(
      accountProvider: accountProvider,
      categoryProvider: categoryProvider,
      transactionProvider: transactionProvider,
      budgetProvider: budgetProvider,
      recurringProvider: recurringProvider,
      bundle: ledger.toBundle(),
    );
    return result;
  }

  /// 远端 revision 更大时拉齐并覆盖本地 Provider；本地已新或相等则不动。
  /// 返回是否用远端覆盖了本地。
  static Future<bool> ensureFresh(BuildContext context) async {
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final recurringProvider = context.read<RecurringProvider>();

    final config = await CloudSyncService.loadConfig();
    if (config == null || !CloudSyncService.isSupportedOnCurrentPlatform) {
      return false;
    }
    final remote = await CloudSyncService.ensureFreshIfNeeded(config);
    if (remote == null) {
      return false;
    }
    await _applyBundle(
      accountProvider: accountProvider,
      categoryProvider: categoryProvider,
      transactionProvider: transactionProvider,
      budgetProvider: budgetProvider,
      recurringProvider: recurringProvider,
      bundle: remote,
    );
    await CloudSyncService.setLocalRevision(remote.revision);
    await CloudSyncService.markSyncNow();
    return true;
  }

  static Future<void> _applyBundle({
    required AccountProvider accountProvider,
    required CategoryProvider categoryProvider,
    required TransactionProvider transactionProvider,
    required BudgetProvider budgetProvider,
    required RecurringProvider recurringProvider,
    required LedgerBundle bundle,
  }) async {
    final normalized = Ledger(bundle).toBundle();
    await accountProvider.replaceAll(normalized.accounts);
    await accountProvider.replaceLenders(normalized.lenders);
    await categoryProvider.replaceAll(normalized.categories);
    await transactionProvider.replaceAll(normalized.transactions);
    await budgetProvider.replaceAll(normalized.budgets);
    await recurringProvider.replaceAll(normalized.recurringRules);
  }
}
