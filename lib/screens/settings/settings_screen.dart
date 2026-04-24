import 'package:flutter/material.dart';
import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/screens/settings/category_management_screen.dart';
import 'package:finance_app/screens/settings/security_privacy_screen.dart';
import 'package:finance_app/services/data_export_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/github_sync_setup_screen.dart'
    as finance_webdav_setup;
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

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
        centerTitle: true,
        title: Text(
          '设置',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          children: [
            _buildProfileSummary(context),
            const SizedBox(height: 32),
            _buildPreferencesSection(context),
            const SizedBox(height: 32),
            _buildSecuritySection(context),
            const SizedBox(height: 32),
            _buildSupportSection(context),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
            const SizedBox(height: 80), // Padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
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
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryFixed,
              border: Border.all(
                color: AppColors.surfaceContainerLowest,
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '旺财',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '本地优先 · 数据自主可控',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            '偏好设置',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
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
              _buildSettingsItem(
                context,
                Icons.category,
                '分类管理',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryManagementScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                Icons.ios_share,
                '导出数据',
                onTap: _isExporting ? () {} : () => _showExportSheet(context),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                Icons.sync,
                'WebDAV 云备份',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const finance_webdav_setup.WebDavBackupSetupScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                context,
                Icons.dark_mode,
                '应用主题',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '浅色',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            '安全与隐私',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _buildSettingsItem(
            context,
            Icons.lock,
            '安全 (面容ID/密码)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SecurityPrivacyScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            '支持',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _buildSettingsItem(context, Icons.info_outline, '关于'),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String label, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: AppColors.outlineVariant.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.errorContainer),
        ),
      ),
      child: Text(
        '退出登录',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.error),
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择导出格式',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JSON 包含完整备份数据，CSV 便于表格查看。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 12),
                _buildExportOptionTile(
                  context: context,
                  icon: Icons.data_object,
                  label: '导出 JSON',
                  subtitle: '完整数据备份',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _exportData(ExportFormat.json);
                  },
                ),
                _buildDivider(),
                _buildExportOptionTile(
                  context: context,
                  icon: Icons.table_view,
                  label: '导出 CSV',
                  subtitle: '可用 Excel 打开',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _exportData(ExportFormat.csv);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOptionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.secondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Future<void> _exportData(ExportFormat format) async {
    setState(() {
      _isExporting = true;
    });
    try {
      final bundle = _buildBackupBundle();
      await DataExportService.export(bundle: bundle, format: format);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(format == ExportFormat.json ? 'JSON 导出成功' : 'CSV 导出成功'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  AppBackupBundle _buildBackupBundle() {
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    return AppBackupBundle(
      version: 1,
      exportedAt: DateTime.now(),
      accounts: accountProvider.accounts,
      lenders: accountProvider.lenders,
      categories: categoryProvider.categories,
      transactions: transactionProvider.transactions,
    );
  }
}
