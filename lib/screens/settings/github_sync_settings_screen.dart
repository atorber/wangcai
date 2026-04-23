import 'package:flutter/material.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/github_sync_status_screen.dart' as finance_sync_status;

class GithubSyncSettingsScreen extends StatefulWidget {
  const GithubSyncSettingsScreen({super.key});

  @override
  State<GithubSyncSettingsScreen> createState() => _GithubSyncSettingsScreenState();
}

class _GithubSyncSettingsScreenState extends State<GithubSyncSettingsScreen> {
  String _selectedRepo = 'finance-data-sync';
  String _selectedFormat = 'json';
  String _selectedFrequency = 'realtime';

  final List<String> _repos = [
    'finance-data-sync',
    'personal-budget-backup',
    'wealth-tracker-export',
  ];

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
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBjtiyC9skOsN1SqwTx2xGVzrYyyc_52lVFJeq5g5rZhaGof5oq8iPyx-QT1z32aTExPLKYVwMQVaT4EyoUB8EfRfNj_Nj-TFcZtKCpkNPpMr22jbJh2btbZSuGlKqtRy87brH1vtdwCW4w9qFoXUHuvM5bvpiXx-upTstLVWNAsReb4Ugi-Zgh6KBuFXjJtfVPmeqZrltoFpq2z4C18YUPjFTHKC6p8ElakXF6Wqzl5uy6GLzj2k8dsvd9axfHmEV0gB8oas9_6ogM',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '仓库设置',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '配置您的数据同步目标和偏好设置。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              _buildRepoSelection(context),
              const SizedBox(height: 32),
              _buildSyncSettings(context),
              const SizedBox(height: 32),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepoSelection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Text(
            '选择同步仓库',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRepo,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
                items: _repos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRepo = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.surfaceVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '或',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                      ),
                ),
              ),
              Expanded(child: Container(height: 1, color: AppColors.surfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  '新建仓库',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Text(
            '同步文件格式',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormatRadio('JSON', 'json'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatRadio('CSV', 'csv'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '同步频率',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildFrequencyRadio('实时同步', '每次数据变更立即推送到仓库', 'realtime'),
                _buildFrequencyRadio('每日同步', '每天 UTC 00:00 汇总同步一次', 'daily'),
                _buildFrequencyRadio('手动同步', '仅在点击同步按钮时执行', 'manual'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRadio(String label, String value) {
    final isSelected = _selectedFormat == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildFrequencyRadio(String title, String subtitle, String value) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
      ),
      value: value,
      groupValue: _selectedFrequency,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedFrequency = newValue;
          });
        }
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const finance_sync_status.GithubSyncStatusScreen(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, size: 20),
          const SizedBox(width: 16),
          Text(
            '完成设置',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
