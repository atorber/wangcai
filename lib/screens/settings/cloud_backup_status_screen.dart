import 'package:flutter/material.dart';
import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/cloud_sync_config.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/budget_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/recurring_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/cloud_sync_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart' show CloudSyncException;

class CloudBackupStatusScreen extends StatefulWidget {
  const CloudBackupStatusScreen({super.key});

  @override
  State<CloudBackupStatusScreen> createState() =>
      _CloudBackupStatusScreenState();
}

class _CloudBackupStatusScreenState extends State<CloudBackupStatusScreen> {
  CloudSyncConfig? _config;
  String? _lastSyncAt;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final protocolLabel = _config?.protocolLabel ?? '云';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$protocolLabel 备份',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 32.0,
                ),
                child: Column(
                  children: [
                    if (!CloudSyncService.isSupportedOnCurrentPlatform) ...[
                      _buildWebUnsupportedBanner(context),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 48),
                    _buildStatusIndicator(context),
                    const SizedBox(height: 48),
                    _buildDetailsCard(context),
                    const Spacer(),
                    _buildActionButtons(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.check, color: AppColors.onPrimary, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          _lastSyncAt == null ? '尚未备份' : '备份配置可用',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final isS3 = _config?.protocol == CloudSyncProtocol.s3;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
        children: [
          _detailRow(context, '最后备份', _lastSyncAt ?? '--'),
          const SizedBox(height: 24),
          _detailRow(context, '协议', _config?.protocolLabel ?? '--'),
          const SizedBox(height: 16),
          _detailRow(
            context,
            isS3 ? 'Bucket / 目录' : '服务地址',
            _config?.displayTarget ?? '--',
          ),
          const SizedBox(height: 16),
          _detailRow(
            context,
            isS3 ? 'Endpoint' : '远端目录',
            _config?.displayPath ?? '--',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebUnsupportedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        CloudSyncService.unsupportedPlatformMessage,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              height: 1.45,
            ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final protocolLabel = _config?.protocolLabel ?? '云端';
    final canSync =
        !_syncing && CloudSyncService.isSupportedOnCurrentPlatform;
    return Column(
      children: [
        ElevatedButton(
          onPressed: canSync ? _uploadNow : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 20),
              const SizedBox(width: 8),
              Text(
                '立即备份到 $protocolLabel',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: canSync ? _downloadNow : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_download, size: 20),
              const SizedBox(width: 8),
              Text(
                '从 $protocolLabel 恢复覆盖本地',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _init() async {
    final config = await CloudSyncService.loadConfig();
    final lastSyncAt = await CloudSyncService.getLastSyncAt();
    if (!mounted) {
      return;
    }
    setState(() {
      _config = config;
      _lastSyncAt = lastSyncAt;
      _loading = false;
    });
  }

  Future<void> _uploadNow() async {
    if (!CloudSyncService.isSupportedOnCurrentPlatform) {
      _showMessage(CloudSyncService.unsupportedPlatformMessage);
      return;
    }
    if (_config == null) {
      _showMessage('请先在上一步保存云备份配置');
      return;
    }
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final recurringProvider = context.read<RecurringProvider>();
    setState(() => _syncing = true);
    try {
      final localRevision = await CloudSyncService.getLocalRevision();
      AppBackupBundle? remoteMeta;
      try {
        remoteMeta = await CloudSyncService.fetchRemoteBundleMeta(_config!);
      } catch (_) {
        remoteMeta = null;
      }
      final now = DateTime.now();
      var force = false;
      if (remoteMeta != null && remoteMeta.revision > localRevision) {
        final shouldContinue = await _confirmRiskyAction(
          title: '远端版本更新',
          content:
              '远端 revision (${remoteMeta.revision}) 新于本地 ($localRevision)。继续上传将覆盖远端，是否继续？',
          confirmText: '继续覆盖',
        );
        if (!shouldContinue) {
          return;
        }
        force = true;
      } else if (remoteMeta != null && remoteMeta.exportedAt.isAfter(now)) {
        final shouldContinue = await _confirmRiskyAction(
          title: '检测到远端备份时间更新',
          content:
              '远端备份时间 (${remoteMeta.exportedAt.toIso8601String()}) 晚于当前设备时间，继续上传会覆盖远端版本，是否继续？',
          confirmText: '继续覆盖',
        );
        if (!shouldContinue) {
          return;
        }
        force = true;
      }
      final bundle = AppBackupBundle(
        version: 1,
        schemaVersion: 2,
        revision: localRevision,
        exportedAt: now,
        accounts: accountProvider.accounts,
        lenders: accountProvider.lenders,
        categories: categoryProvider.categories,
        transactions: transactionProvider.transactions,
        budgets: budgetProvider.budgets,
        recurringRules: recurringProvider.rules,
      );
      await CloudSyncService.uploadBackup(_config!, bundle, force: force);
      _lastSyncAt = await CloudSyncService.getLastSyncAt();
      _showMessage('备份成功（已加锁同步）');
      setState(() {});
    } on CloudSyncException catch (e) {
      if (e.code == 'CONFLICT') {
        _showMessage('备份冲突：$e');
      } else if (e.code == 'LOCK_BUSY') {
        _showMessage('云端账本正在被其他端写入，请稍后重试');
      } else {
        _showMessage('备份失败：$e');
      }
    } catch (e) {
      _showMessage('备份失败：$e');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _downloadNow() async {
    if (!CloudSyncService.isSupportedOnCurrentPlatform) {
      _showMessage(CloudSyncService.unsupportedPlatformMessage);
      return;
    }
    if (_config == null) {
      _showMessage('请先在上一步保存云备份配置');
      return;
    }
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final recurringProvider = context.read<RecurringProvider>();
    final hasLocalData =
        transactionProvider.transactions.isNotEmpty ||
        accountProvider.accounts.isNotEmpty ||
        accountProvider.lenders.isNotEmpty;
    setState(() => _syncing = true);
    try {
      final localRevision = await CloudSyncService.getLocalRevision();
      AppBackupBundle? remoteMeta;
      try {
        remoteMeta = await CloudSyncService.fetchRemoteBundleMeta(_config!);
      } catch (_) {
        remoteMeta = null;
      }
      if (remoteMeta != null &&
          hasLocalData &&
          remoteMeta.revision < localRevision) {
        final shouldContinue = await _confirmRiskyAction(
          title: '远端版本可能较旧',
          content:
              '远端 revision (${remoteMeta.revision}) 小于本地 ($localRevision)，继续恢复会丢失本地较新数据，是否继续？',
          confirmText: '仍然恢复',
        );
        if (!shouldContinue) {
          return;
        }
      }
      final bundle = await CloudSyncService.downloadBackup(_config!);
      await accountProvider.replaceAll(bundle.accounts);
      await accountProvider.replaceLenders(bundle.lenders);
      await categoryProvider.replaceAll(bundle.categories);
      await transactionProvider.replaceAll(bundle.transactions);
      await budgetProvider.replaceAll(bundle.budgets);
      await recurringProvider.replaceAll(bundle.recurringRules);
      _lastSyncAt = await CloudSyncService.getLastSyncAt();
      _showMessage(
        '恢复完成：${bundle.transactions.length} 条账单，${bundle.accounts.length} 个账户，'
        '${bundle.lenders.length} 个应收/应付，${bundle.categories.length} 个分类'
        '（revision ${bundle.revision}）',
      );
      setState(() {});
    } on CloudSyncException catch (e) {
      if (e.code == 'LOCK_BUSY') {
        _showMessage('云端账本正在被其他端写入，请稍后重试');
      } else {
        _showMessage('恢复失败：$e');
      }
    } catch (e) {
      _showMessage('恢复失败：$e');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirmRiskyAction({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    if (!mounted) {
      return false;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

/// 兼容旧入口名称。
typedef WebDavBackupStatusScreen = CloudBackupStatusScreen;
