import 'package:flutter/material.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/home/asset_overview_screen.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/screens/stats/financial_stats_screen.dart';
import 'package:finance_app/screens/home/monthly_overview_screen.dart';
import 'package:finance_app/screens/settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MonthlyOverviewScreen(), // Setting Monthly Overview as Home for now, although in real app it might be toggleable
    const FinancialStatsScreen(),
    const Center(child: Text('添加 (Add)')), // Add Transaction (Modal/Screen)
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionScreen(),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF09090b) // zinc-950
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF18181b) // zinc-900
                  : const Color(0xFFf4f4f5), // zinc-100
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000), // rgba(0,0,0,0.04)
              blurRadius: 20,
              offset: Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, '首页'),
                _buildNavItem(1, Icons.bar_chart, '统计'),
                _buildAddNavItem(),
                _buildNavItem(3, Icons.settings, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected && index == 3 // Special styling for settings in Screen 1
            ? BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.secondary.withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.secondary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNavItem() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_circle,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '添加',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
