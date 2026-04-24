import 'package:flutter/material.dart';
import 'package:finance_app/providers/security_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '安全与隐私',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, securityProvider, _) {
          if (!securityProvider.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                context,
                children: [
                  SwitchListTile(
                    value: securityProvider.appLockEnabled,
                    onChanged: (value) async {
                      if (value && !securityProvider.hasPinCode) {
                        await _showPinDialog(context, securityProvider);
                        if (!securityProvider.hasPinCode) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请先设置 PIN 码，再启用应用锁')),
                            );
                          }
                          return;
                        }
                      }
                      await securityProvider.setAppLockEnabled(value);
                    },
                    title: const Text('启用应用锁'),
                    subtitle: const Text('进入应用时需要身份验证'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: securityProvider.biometricEnabled,
                    onChanged: securityProvider.appLockEnabled
                        ? (value) async {
                            await securityProvider.setBiometricEnabled(value);
                          }
                        : null,
                    title: const Text('面容/指纹解锁'),
                    subtitle: const Text('优先使用生物识别快速解锁'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('PIN 码'),
                    subtitle: Text(
                      securityProvider.hasPinCode ? '已设置' : '未设置',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPinDialog(context, securityProvider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                children: [
                  SwitchListTile(
                    value: securityProvider.privacyModeEnabled,
                    onChanged: (value) async {
                      await securityProvider.setPrivacyModeEnabled(value);
                    },
                    title: const Text('隐私模式'),
                    subtitle: const Text('在公开场景隐藏敏感金额信息'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '说明：启用应用锁后，冷启动和回到前台都需要进行身份验证。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Future<void> _showPinDialog(
    BuildContext context,
    SecurityProvider securityProvider,
  ) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置 PIN 码'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '请输入 4-6 位数字',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final pin = controller.text.trim();
      if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN 码需为 4-6 位数字')),
          );
        }
      } else {
        await securityProvider.setPinCode(pin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN 码已保存')),
          );
        }
      }
    }
    controller.dispose();
  }
}
