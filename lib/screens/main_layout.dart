import 'package:flutter/material.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/screens/home/asset_overview_screen.dart';
import 'package:finance_app/screens/add/add_transaction_screen.dart';
import 'package:finance_app/screens/bills/bill_list_screen.dart';
import 'package:finance_app/screens/stats/financial_stats_screen.dart';
import 'package:finance_app/screens/settings/settings_screen.dart';
import 'package:finance_app/providers/account_provider.dart';
import 'package:finance_app/providers/recurring_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/cloud_ledger_bridge.dart';
import 'package:provider/provider.dart';
import 'package:wangcai_core/wangcai_core.dart' show CloudSyncException;

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _recurringSyncStarted = false;

  List<Widget> get _screens => [
    const AssetOverviewScreen(),
    const FinancialStatsScreen(),
    AddTransactionScreen(onSaved: _switchToBillTab),
    const BillListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecurringBills());
  }

  Future<void> _syncRecurringBills() async {
    if (_recurringSyncStarted || !mounted) {
      return;
    }
    _recurringSyncStarted = true;

    final recurring = context.read<RecurringProvider>();
    final transactions = context.read<TransactionProvider>();
    final accounts = context.read<AccountProvider>();

    Future<void> run() async {
      if (!recurring.loaded || !transactions.loaded || !accounts.loaded) {
        return;
      }
      try {
        await CloudLedgerBridge.ensureFresh(context);
        if (!mounted) {
          return;
        }
        final created = await CloudLedgerBridge.mutate(
          context,
          action: (ledger) async {
            return ledger.runDueRecurring();
          },
        );
        if (created > 0 && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已自动入账 $created 笔周期账单')));
        }
      } on CloudSyncException catch (e) {
        if (!mounted) {
          return;
        }
        if (e.code == 'LOCK_BUSY') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('云端账本正被其他端写入，周期入账稍后重试')),
          );
        }
      }
    }

    if (recurring.loaded && transactions.loaded && accounts.loaded) {
      await run();
      return;
    }

    void listener() {
      if (recurring.loaded && transactions.loaded && accounts.loaded) {
        recurring.removeListener(listener);
        transactions.removeListener(listener);
        accounts.removeListener(listener);
        run();
      }
    }

    recurring.addListener(listener);
    transactions.addListener(listener);
    accounts.addListener(listener);
  }

  void _switchToBillTab() {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentIndex = 3;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF09090b)
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF18181b)
                  : const Color(0xFFf4f4f5),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, '首页'),
                _buildNavItem(1, Icons.bar_chart, '统计'),
                _buildNavItem(2, Icons.add_circle, '添加'),
                _buildNavItem(3, Icons.receipt_long, '账单'),
                _buildNavItem(4, Icons.settings, '设置'),
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
        decoration: isSelected && index == 4
            ? BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
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
                  : AppColors.secondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.secondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
