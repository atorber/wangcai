import 'package:flutter/material.dart';
import 'package:finance_app/models/cloud_sync_config.dart';
import 'package:finance_app/models/webdav_backup_config.dart';
import 'package:finance_app/services/cloud_sync_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/cloud_backup_status_screen.dart';

class CloudBackupSetupScreen extends StatefulWidget {
  const CloudBackupSetupScreen({super.key});

  @override
  State<CloudBackupSetupScreen> createState() => _CloudBackupSetupScreenState();
}

class _CloudBackupSetupScreenState extends State<CloudBackupSetupScreen> {
  CloudSyncProtocol _protocol = CloudSyncProtocol.webdav;

  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController(text: '/wangcai/records.json');

  final _endpointController = TextEditingController();
  final _regionController = TextEditingController(text: 'us-east-1');
  final _bucketController = TextEditingController();
  final _objectKeyController = TextEditingController(text: 'wangcai/records.json');
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _forcePathStyle = true;

  bool _loading = true;
  bool _obscureSecret = true;

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
    _endpointController.dispose();
    _regionController.dispose();
    _bucketController.dispose();
    _objectKeyController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
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
          '云备份',
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                children: [
                  _buildHeaderSection(context),
                  const SizedBox(height: 24),
                  _buildProtocolSelector(context),
                  const SizedBox(height: 24),
                  if (_protocol == CloudSyncProtocol.webdav)
                    ..._buildWebDavFields(context)
                  else
                    ..._buildS3Fields(context),
                  const SizedBox(height: 24),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.onPrimary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
          child: const Icon(
            Icons.cloud_sync,
            color: AppColors.primaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '配置云备份',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持 WebDAV 与 S3 兼容存储（MinIO / R2 / OSS 等）。账本为同一份 JSON，可与技能多端同步。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildProtocolSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '同步协议',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<CloudSyncProtocol>(
          segments: const [
            ButtonSegment(
              value: CloudSyncProtocol.webdav,
              label: Text('WebDAV'),
              icon: Icon(Icons.folder_shared_outlined, size: 18),
            ),
            ButtonSegment(
              value: CloudSyncProtocol.s3,
              label: Text('S3'),
              icon: Icon(Icons.storage_outlined, size: 18),
            ),
          ],
          selected: {_protocol},
          onSelectionChanged: (selected) {
            setState(() => _protocol = selected.first);
          },
        ),
      ],
    );
  }

  List<Widget> _buildWebDavFields(BuildContext context) {
    return [
      _buildInputField(
        context,
        label: '服务地址',
        hint: '例如: https://dav.example.com/remote.php/dav/files/user',
        controller: _serverUrlController,
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: '用户名',
        hint: '例如: user',
        controller: _usernameController,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: '密码 / App Password',
        hint: '请输入 WebDAV 密码',
        controller: _passwordController,
        obscureText: _obscureSecret,
        onToggleObscure: () {
          setState(() => _obscureSecret = !_obscureSecret);
        },
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: '远端文件路径',
        hint: '例如: /wangcai/records.json',
        controller: _pathController,
      ),
      const SizedBox(height: 8),
      Text(
        '确保 WebDAV 账号对目标路径有读写权限',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondary,
            ),
      ),
    ];
  }

  List<Widget> _buildS3Fields(BuildContext context) {
    return [
      _buildInputField(
        context,
        label: 'Endpoint',
        hint: '例如: https://s3.example.com 或 https://xxx.r2.cloudflarestorage.com',
        controller: _endpointController,
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: 'Region',
        hint: '例如: us-east-1 / auto',
        controller: _regionController,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: 'Bucket',
        hint: '例如: wangcai',
        controller: _bucketController,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: 'Object Key',
        hint: '例如: wangcai/records.json',
        controller: _objectKeyController,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: 'Access Key ID',
        hint: 'Access Key',
        controller: _accessKeyController,
      ),
      const SizedBox(height: 12),
      _buildInputField(
        context,
        label: 'Secret Access Key',
        hint: 'Secret Key',
        controller: _secretKeyController,
        obscureText: _obscureSecret,
        onToggleObscure: () {
          setState(() => _obscureSecret = !_obscureSecret);
        },
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Path-style 访问',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        subtitle: Text(
          'MinIO / 自托管建议开启；部分云厂商可用虚拟主机样式',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
              ),
        ),
        value: _forcePathStyle,
        onChanged: (value) => setState(() => _forcePathStyle = value),
      ),
    ];
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
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
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadConfig() async {
    final current = await CloudSyncService.loadConfig();
    final drafts = await CloudSyncService.loadDraftConfigs();
    if (current != null) {
      _protocol = current.protocol;
    }
    final webdav = drafts.webdav;
    if (webdav != null) {
      _serverUrlController.text = webdav.serverUrl;
      _usernameController.text = webdav.username;
      _passwordController.text = webdav.password;
      _pathController.text = webdav.remotePath;
    }
    final s3 = drafts.s3;
    if (s3 != null) {
      _endpointController.text = s3.endpoint;
      _regionController.text = s3.region;
      _bucketController.text = s3.bucket;
      _objectKeyController.text = s3.objectKey;
      _accessKeyController.text = s3.accessKeyId;
      _secretKeyController.text = s3.secretAccessKey;
      _forcePathStyle = s3.forcePathStyle;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAndNext() async {
    final CloudSyncConfig config;
    if (_protocol == CloudSyncProtocol.webdav) {
      config = CloudSyncConfig(
        protocol: CloudSyncProtocol.webdav,
        webdav: WebDavBackupConfig(
          serverUrl: _serverUrlController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          remotePath: _pathController.text.trim(),
        ),
      );
    } else {
      config = CloudSyncConfig(
        protocol: CloudSyncProtocol.s3,
        s3: S3BackupConfig(
          endpoint: _endpointController.text.trim(),
          region: _regionController.text.trim().isEmpty
              ? 'us-east-1'
              : _regionController.text.trim(),
          bucket: _bucketController.text.trim(),
          objectKey: _objectKeyController.text.trim(),
          accessKeyId: _accessKeyController.text.trim(),
          secretAccessKey: _secretKeyController.text.trim(),
          forcePathStyle: _forcePathStyle,
        ),
      );
    }

    if (!config.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _protocol == CloudSyncProtocol.webdav
                ? '请完整填写 WebDAV 配置'
                : '请完整填写 S3 配置',
          ),
        ),
      );
      return;
    }

    await CloudSyncService.saveConfig(config);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CloudBackupStatusScreen()),
    );
  }
}

/// 兼容旧入口名称。
typedef WebDavBackupSetupScreen = CloudBackupSetupScreen;
