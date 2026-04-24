import 'package:flutter/material.dart';
import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/webdav_backup_config.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/webdav_backup_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class WebDavBackupStatusScreen extends StatefulWidget {
  const WebDavBackupStatusScreen({super.key});

  @override
  State<WebDavBackupStatusScreen> createState() => _WebDavBackupStatusScreenState();
}

class _WebDavBackupStatusScreenState extends State<WebDavBackupStatusScreen> {
  WebDavBackupConfig? _config;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withOpacity(0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withOpacity(0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'WebDAV 备份',
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                child: Column(
                  children: [
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
              )
            ],
          ),
          child: const Icon(
            Icons.check,
            color: AppColors.onPrimary,
            size: 48,
          ),
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
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最后备份',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                _lastSyncAt ?? '--',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WebDAV 服务',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                _config?.serverUrl ?? '--',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '远端路径',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                _config?.remotePath ?? '--',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _syncing ? null : _uploadNow,
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
                '立即备份到 WebDAV',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _syncing ? null : _downloadNow,
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
                '从 WebDAV 恢复覆盖本地',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _init() async {
    final config = await WebDavBackupService.loadConfig();
    final lastSyncAt = await WebDavBackupService.getLastSyncAt();
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
    if (_config == null) {
      _showMessage('请先在上一步保存 WebDAV 配置');
      return;
    }
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    setState(() => _syncing = true);
    try {
      final remoteMeta = await WebDavBackupService.fetchRemoteBundleMeta(_config!);
      final now = DateTime.now();
      if (remoteMeta != null && remoteMeta.exportedAt.isAfter(now)) {
        final shouldContinue = await _confirmRiskyAction(
          title: '检测到远端备份时间更新',
          content:
              '远端备份时间 (${remoteMeta.exportedAt.toIso8601String()}) 晚于当前设备时间，继续上传会覆盖远端版本，是否继续？',
          confirmText: '继续覆盖',
        );
        if (!shouldContinue) {
          return;
        }
      }
      final bundle = AppBackupBundle(
        version: 1,
        exportedAt: now,
        accounts: accountProvider.accounts,
        lenders: accountProvider.lenders,
        categories: categoryProvider.categories,
        transactions: transactionProvider.transactions,
      );
      await WebDavBackupService.uploadBackup(_config!, bundle);
      _lastSyncAt = await WebDavBackupService.getLastSyncAt();
      _showMessage('备份成功');
      setState(() {});
    } catch (e) {
      _showMessage('备份失败：$e');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _downloadNow() async {
    if (_config == null) {
      _showMessage('请先在上一步保存 WebDAV 配置');
      return;
    }
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final hasLocalData = transactionProvider.transactions.isNotEmpty ||
        accountProvider.accounts.isNotEmpty ||
        accountProvider.lenders.isNotEmpty;
    setState(() => _syncing = true);
    try {
      final bundle = await WebDavBackupService.downloadBackup(_config!);
      final localLatestTxAt = transactionProvider.transactions.isEmpty
          ? null
          : transactionProvider.transactions
              .map((item) => item.date)
              .reduce((a, b) => a.isAfter(b) ? a : b);
      final remoteOlderThanLocal = hasLocalData &&
          localLatestTxAt != null &&
          bundle.exportedAt.isBefore(localLatestTxAt);
      if (remoteOlderThanLocal) {
        final shouldContinue = await _confirmRiskyAction(
          title: '远端备份可能较旧',
          content:
              '远端备份时间 (${bundle.exportedAt.toIso8601String()}) 早于本地最新账单时间 (${localLatestTxAt.toIso8601String()})，继续恢复会丢失本地较新数据，是否继续？',
          confirmText: '仍然恢复',
        );
        if (!shouldContinue) {
          return;
        }
      }
      await accountProvider.replaceAll(bundle.accounts);
      await accountProvider.replaceLenders(bundle.lenders);
      await categoryProvider.replaceAll(bundle.categories);
      await transactionProvider.replaceAll(bundle.transactions);
      _lastSyncAt = await WebDavBackupService.getLastSyncAt();
      _showMessage(
        '恢复完成：${bundle.transactions.length} 条账单，${bundle.accounts.length} 个账户，${bundle.lenders.length} 个借贷人，${bundle.categories.length} 个分类',
      );
      setState(() {});
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
