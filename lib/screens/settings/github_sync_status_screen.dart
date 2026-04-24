import 'package:flutter/material.dart';
import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/models/github_sync_config.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/github_sync_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class GithubSyncStatusScreen extends StatefulWidget {
  const GithubSyncStatusScreen({super.key});

  @override
  State<GithubSyncStatusScreen> createState() => _GithubSyncStatusScreenState();
}

class _GithubSyncStatusScreenState extends State<GithubSyncStatusScreen> {
  GithubSyncConfig? _config;
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
          'GitHub Sync',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBUy4wiAIpIgepftbbisFvXzVzm-VQmuD1HPbCB7jgukm_IwE-BdgEeOzWg4kjjE9YNv3R3TMJWnlUAQRWnHXpazickgL66tDHmw4ikv6cEu2G8DGcikQPUNLZSonfMRNdKPIs8aFo5jlLVSBViWrK_3Lu3q3Af8i1FgF7YiQGjtVnEN_Eq_myKU84RTHJmWC79O2ldr6tV5zDVtZAo6z4UPtnViWVenSx9nigfrSyR4AwB_RhFgS9Yj8qFEcRfkzhBp3CRTwuZpllT',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
              ),
            ),
          ),
        ],
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
          _lastSyncAt == null ? '尚未同步' : '同步配置可用',
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
                '最后同步',
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
                '目标仓库',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                _config == null ? '--' : '${_config!.owner}/${_config!.repo}',
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
                '云端文件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                _config?.path ?? '--',
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
                '上传到 GitHub',
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
                '从 GitHub 下载覆盖本地',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _init() async {
    final config = await GithubSyncService.loadConfig();
    final lastSyncAt = await GithubSyncService.getLastSyncAt();
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
      _showMessage('请先在上一步保存 GitHub 配置');
      return;
    }
    setState(() => _syncing = true);
    try {
      final bundle = AppBackupBundle(
        version: 1,
        exportedAt: DateTime.now(),
        accounts: context.read<AccountProvider>().accounts,
        lenders: context.read<AccountProvider>().lenders,
        categories: context.read<CategoryProvider>().categories,
        transactions: context.read<TransactionProvider>().transactions,
      );
      await GithubSyncService.uploadBackup(_config!, bundle);
      _lastSyncAt = await GithubSyncService.getLastSyncAt();
      _showMessage('上传成功');
      setState(() {});
    } catch (e) {
      _showMessage('上传失败：$e');
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _downloadNow() async {
    if (_config == null) {
      _showMessage('请先在上一步保存 GitHub 配置');
      return;
    }
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    setState(() => _syncing = true);
    try {
      final bundle = await GithubSyncService.downloadBackup(_config!);
      await accountProvider.replaceAll(bundle.accounts);
      await accountProvider.replaceLenders(bundle.lenders);
      await categoryProvider.replaceAll(bundle.categories);
      await transactionProvider.replaceAll(bundle.transactions);
      _lastSyncAt = await GithubSyncService.getLastSyncAt();
      _showMessage(
        '恢复完成：${bundle.transactions.length} 条账单，${bundle.accounts.length} 个账户，${bundle.lenders.length} 个借贷人，${bundle.categories.length} 个分类',
      );
      setState(() {});
    } catch (e) {
      _showMessage('下载失败：$e');
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
}
