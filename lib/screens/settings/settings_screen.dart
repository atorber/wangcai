import 'package:flutter/material.dart';
import 'package:finance_app/screens/settings/category_management_screen.dart';
import 'package:finance_app/screens/settings/security_privacy_screen.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/settings/github_sync_setup_screen.dart' as finance_sync_setup;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDn1Sb7I1cqJaCPTTBaGihmjkruba2PNv5-6HYTWdwR9A9-sPrv_xETico3RKMac_WyIovqs8NVomTLa3kYcTrKvtRT6MlsF_t6farKWJzM2cxRZV4SAv7TjnHTDiE4txZuZKbgnll4RbwAEck84BUpvC9BWNAFVPDrAmCWpR4hgGqXRWkQ7J77zdPsY7qvSpCZ1iskHaMzIQbWXLO01HzGRFd9NKFyeDhSrdAO3zFJYGOgMso8ZUuW-KVOHW-w-e-u3hC86X4snJyb',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '财务',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
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
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceContainerLowest, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAgHOfKrhzCg_YqzdqZ6NFVx-7jl5NyMIK8VTCJtQl5KoELdKCAuQYhJgU_8_xBOZLu9JaPzk8oOTicbVCERmRWfo8OhjJSMTNkjer9tAdUjfqknEhW_26eYyPY_cgxIkJ_JBntxCvxUyRbyB2fmLJPM-zYqkDDfDmh7RhMPRG67mBrLiOY2iJepkTW1YzUlFvhLKMTvxmgwBDhk0T5JWSDcbqyolcIhKJn-2Xv3R1KzEGUZ3Vnt5JbVBoLMYHOk-3Ma9CrnCIRKoNW',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 48),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceContainerLowest, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: AppColors.onPrimary, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Alex Thompson',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '高级会员',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
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
              )
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
              _buildSettingsItem(context, Icons.ios_share, '导出数据'),
              _buildDivider(),
              _buildSettingsItem(
                context,
                Icons.sync,
                '同步到 GitHub',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const finance_sync_setup.GithubSyncSetupScreen(),
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
                    const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
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
              )
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
              )
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                      ),
                ),
              ],
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.error,
            ),
      ),
    );
  }
}
