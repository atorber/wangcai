import 'package:flutter/material.dart';
import 'package:finance_app/providers/security_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:local_auth/local_auth.dart';
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
                      if (value) {
                        final canUseBiometrics = await _canUseBiometrics();
                        if (!canUseBiometrics) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('请先在系统中设置面容或指纹'),
                              ),
                            );
                          }
                          return;
                        }
                        if (!securityProvider.biometricEnabled) {
                          await securityProvider.setBiometricEnabled(true);
                        }
                      }
                      await securityProvider.setAppLockEnabled(value);
                    },
                    title: const Text('启用应用锁'),
                    subtitle: const Text('使用面容或指纹解锁'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: securityProvider.biometricEnabled,
                    onChanged: securityProvider.appLockEnabled
                        ? (value) async {
                            if (!value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('应用锁需要保留系统解锁'),
                                ),
                              );
                              return;
                            }
                            await securityProvider.setBiometricEnabled(value);
                          }
                        : null,
                    title: const Text('生物识别解锁'),
                    subtitle: const Text('仅使用系统面容或指纹'),
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
                '说明：启用应用锁后，冷启动和回到前台仅调用系统生物识别，不提供其他解锁方式。',
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

  Future<bool> _canUseBiometrics() async {
    final localAuth = LocalAuthentication();
    try {
      final availableBiometrics = await localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
