import 'package:flutter/material.dart';
import 'package:finance_app/models/github_sync_config.dart';
import 'package:finance_app/services/github_sync_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/github_sync_status_screen.dart' as finance_sync_status;

class GithubSyncSetupScreen extends StatefulWidget {
  const GithubSyncSetupScreen({super.key});

  @override
  State<GithubSyncSetupScreen> createState() => _GithubSyncSetupScreenState();
}

class _GithubSyncSetupScreenState extends State<GithubSyncSetupScreen> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _pathController = TextEditingController(text: 'wangcai/records.json');
  final _branchController = TextEditingController(text: 'main');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _pathController.dispose();
    _branchController.dispose();
    super.dispose();
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
              child: const Icon(Icons.person, color: AppColors.secondary, size: 20),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(context),
              const SizedBox(height: 32),
              _buildFormSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cloud_sync, color: AppColors.primaryContainer, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          '配置 GitHub 同步',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '填写 PAT 和仓库信息。后续可在状态页执行上传或下载。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Access Token',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _tokenController,
              obscureText: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
              decoration: InputDecoration(
                hintText: 'ghp_...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste, color: AppColors.secondary, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInputField(context, label: '仓库所有者', hint: '例如: your-github-id', controller: _ownerController),
          const SizedBox(height: 12),
          _buildInputField(context, label: '仓库名', hint: '例如: finance-backup', controller: _repoController),
          const SizedBox(height: 12),
          _buildInputField(context, label: '文件路径', hint: '例如: wangcai/records.json', controller: _pathController),
          const SizedBox(height: 12),
          _buildInputField(context, label: '分支', hint: 'main', controller: _branchController),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '确保 Token 具有 repo 权限',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              InkWell(
                onTap: () {},
                child: Text(
                  '如何获取？',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _saveAndNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: const Color(0x0A000000),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '保存并前往同步',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadConfig() async {
    final config = await GithubSyncService.loadConfig();
    if (config != null) {
      _tokenController.text = config.token;
      _ownerController.text = config.owner;
      _repoController.text = config.repo;
      _pathController.text = config.path;
      _branchController.text = config.branch;
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveAndNext() async {
    final config = GithubSyncConfig(
      token: _tokenController.text.trim(),
      owner: _ownerController.text.trim(),
      repo: _repoController.text.trim(),
      path: _pathController.text.trim(),
      branch: _branchController.text.trim().isEmpty ? 'main' : _branchController.text.trim(),
    );
    if (!config.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写 GitHub 同步配置')),
      );
      return;
    }
    await GithubSyncService.saveConfig(config);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const finance_sync_status.GithubSyncStatusScreen(),
      ),
    );
  }
}
