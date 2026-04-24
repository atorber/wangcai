import 'package:flutter/material.dart';
import 'package:finance_app/models/webdav_backup_config.dart';
import 'package:finance_app/services/webdav_backup_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/webdav_backup_status_screen.dart' as finance_sync_status;

class WebDavBackupSetupScreen extends StatefulWidget {
  const WebDavBackupSetupScreen({super.key});

  @override
  State<WebDavBackupSetupScreen> createState() => _WebDavBackupSetupScreenState();
}

class _WebDavBackupSetupScreenState extends State<WebDavBackupSetupScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController(text: '/wangcai/records.json');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

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
            color: AppColors.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cloud_sync, color: AppColors.primaryContainer, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          '配置 WebDAV 备份',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '填写 WebDAV 服务地址和账号信息。后续可在状态页执行备份或恢复。',
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
            '服务地址',
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
              controller: _serverUrlController,
              keyboardType: TextInputType.url,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
              decoration: InputDecoration(
                hintText: '例如: https://dav.example.com/remote.php/dav/files/user',
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
          _buildInputField(context, label: '用户名', hint: '例如: user', controller: _usernameController),
          const SizedBox(height: 12),
          _buildInputField(
            context,
            label: '密码 / App Password',
            hint: '请输入 WebDAV 密码',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildInputField(context, label: '远端文件路径', hint: '例如: /wangcai/records.json', controller: _pathController),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '确保 WebDAV 账号有读写权限',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              InkWell(
                onTap: () {},
                child: Text(
                  '查看示例',
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
                  '保存并前往备份',
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
    bool obscureText = false,
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
            obscureText: obscureText,
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
    final config = await WebDavBackupService.loadConfig();
    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _pathController.text = config.remotePath;
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveAndNext() async {
    final config = WebDavBackupConfig(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      remotePath: _pathController.text.trim(),
    );
    if (!config.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写 WebDAV 备份配置')),
      );
      return;
    }
    await WebDavBackupService.saveConfig(config);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const finance_sync_status.WebDavBackupStatusScreen(),
      ),
    );
  }
}
