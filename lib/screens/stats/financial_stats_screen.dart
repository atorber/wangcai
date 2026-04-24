import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_app/models/transaction_record.dart';
import 'package:finance_app/providers/budget_provider.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/security_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/services/stats_service.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:finance_app/widgets/privacy_amount_text.dart';
import 'package:provider/provider.dart';

class FinancialStatsScreen extends StatefulWidget {
  const FinancialStatsScreen({super.key});

  @override
  State<FinancialStatsScreen> createState() => _FinancialStatsScreenState();
}

class _FinancialStatsScreenState extends State<FinancialStatsScreen> {
  StatsPeriod _period = StatsPeriod.month;

  static const List<Color> _palette = [
    AppColors.primaryContainer,
    AppColors.primaryFixedDim,
    AppColors.tertiaryContainer,
    AppColors.tertiaryFixedDim,
    AppColors.secondary,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        centerTitle: true,
        title: Text(
          '统计',
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
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final snapshot = StatsService.build(
            transactions: provider.transactions,
            period: _period,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildPeriodToggle(),
                const SizedBox(height: 24),
                _buildSummaryCard(snapshot),
                const SizedBox(height: 24),
                _buildDonutChartSection(snapshot),
                const SizedBox(height: 24),
                _buildSpendingTrendsSection(snapshot),
                const SizedBox(height: 24),
                _buildBudgetProgressSection(),
                const SizedBox(height: 24),
                _buildInsightsSection(snapshot),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: StatsPeriod.values
            .map((period) {
              final isSelected = _period == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _period = period;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          )
                        : null,
                    child: Text(
                      period.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildSummaryCard(StatsSnapshot snapshot) {
    final balance = snapshot.totalIncome - snapshot.totalExpense;
    final balanceColor = balance >= 0 ? AppColors.primary : AppColors.tertiary;
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _rangeLabel(snapshot),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '结余',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              PrivacyAmountText(
                amount: balance,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: balanceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKeyFigure(
                  label: '收入',
                  amount: snapshot.totalIncome,
                  color: AppColors.primaryContainer,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.surfaceContainer,
              ),
              Expanded(
                child: _buildKeyFigure(
                  label: '支出',
                  amount: snapshot.totalExpense,
                  color: AppColors.onSurface,
                  prefix: '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFigure({
    required String label,
    required double amount,
    required Color color,
    String prefix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        PrivacyAmountText(
          amount: amount,
          sign: prefix,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChartSection(StatsSnapshot snapshot) {
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
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '支出分布',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 24),
          if (!snapshot.hasExpense)
            _buildEmptyChart('当前周期暂无支出记录')
          else ...[
            SizedBox(
              height: 192,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 76,
                      startDegreeOffset: -90,
                      sections: _pieSections(snapshot),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '总计',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        PrivacyAmountText(
                          amount: snapshot.totalExpense,
                          decimalDigits: 0,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLegendGrid(snapshot),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections(StatsSnapshot snapshot) {
    return List.generate(snapshot.categoryBreakdown.length, (index) {
      final item = snapshot.categoryBreakdown[index];
      return PieChartSectionData(
        color: _palette[index % _palette.length],
        value: item.amount,
        title: '',
        radius: 16,
      );
    }, growable: false);
  }

  Widget _buildLegendGrid(StatsSnapshot snapshot) {
    final items = snapshot.categoryBreakdown.take(6).toList(growable: false);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3,
      children: List.generate(items.length, (index) {
        final item = items[index];
        return _buildLegendItem(
          _palette[index % _palette.length],
          item.category,
          '¥${item.amount.toStringAsFixed(2)}',
          '${(item.ratio * 100).toStringAsFixed(0)}%',
        );
      }),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    String amount,
    String ratio,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.onSurface),
              ),
              Text(
                '$amount · $ratio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingTrendsSection(StatsSnapshot snapshot) {
    final deltaRatio = snapshot.expenseDeltaRatio;
    final deltaPercentText = deltaRatio == null
        ? '—'
        : '${deltaRatio >= 0 ? '+' : '-'}${(deltaRatio.abs() * 100).toStringAsFixed(0)}%';
    final deltaColor = deltaRatio == null
        ? AppColors.onSurfaceVariant
        : deltaRatio <= 0
        ? AppColors.primary
        : AppColors.tertiary;
    final deltaIcon = deltaRatio == null
        ? Icons.trending_flat
        : deltaRatio <= 0
        ? Icons.trending_down
        : Icons.trending_up;

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
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '支出趋势',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '日均：',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      PrivacyAmountText(
                        amount: snapshot.avgDailyExpense,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(deltaIcon, color: deltaColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    deltaRatio == null
                        ? '无对比数据'
                        : '相比上一$_periodLabel $deltaPercentText',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: deltaColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!snapshot.hasExpense)
            _buildEmptyChart('暂无支出数据可绘制趋势')
          else
            SizedBox(height: 192, child: _buildTrendBars(snapshot)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendDot(AppColors.primaryContainer, '当前'),
              _buildLegendDot(AppColors.surfaceContainer, '历史'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBars(StatsSnapshot snapshot) {
    final points = snapshot.trendPoints;
    final maxAmount = points.fold<double>(
      0,
      (p, e) => e.amount > p ? e.amount : p,
    );
    final showEveryNLabel = points.length > 12
        ? (points.length / 12).ceil()
        : 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(points.length, (index) {
        final point = points[index];
        final height = maxAmount > 0 ? point.amount / maxAmount : 0.0;
        final showLabel =
            index % showEveryNLabel == 0 || index == points.length - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: height.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: point.isCurrent
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainer,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showLabel ? point.label : '',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: point.isCurrent
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                    fontWeight: point.isCurrent
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBudgetProgressSection() {
    return Consumer3<BudgetProvider, CategoryProvider, TransactionProvider>(
      builder: (context, budgetProvider, categoryProvider, transactionProvider, _) {
        final monthStart = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );
        final nextMonthStart = DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          1,
        );
        final budgets = budgetProvider.budgets;
        return Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '预算进度',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showBudgetEditor(context),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('管理'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (budgets.isEmpty || categoryProvider.categories.isEmpty)
                Text(
                  '尚未设置预算，点击“管理”添加分类预算。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                ...budgets.map((budget) {
                  final matches = categoryProvider.categories.where(
                    (item) => item.id == budget.categoryId,
                  );
                  if (matches.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final category = matches.first;
                  final used = transactionProvider.transactions
                      .where(
                        (item) =>
                            item.type == TransactionType.expense &&
                            item.category == category.label &&
                            !item.date.isBefore(monthStart) &&
                            item.date.isBefore(nextMonthStart),
                      )
                      .fold<double>(0, (sum, item) => sum + item.amount);
                  final ratio = budget.monthlyLimit <= 0
                      ? 0.0
                      : (used / budget.monthlyLimit);
                  final progress = ratio.clamp(0.0, 1.0);
                  final over = ratio > 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(category.label)),
                            Text(
                              '¥${used.toStringAsFixed(2)} / ¥${budget.monthlyLimit.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: over
                                        ? AppColors.error
                                        : AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progress,
                            backgroundColor: AppColors.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              over
                                  ? AppColors.error
                                  : AppColors.primaryContainer,
                            ),
                          ),
                        ),
                        if (over)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '已超预算 ¥${(used - budget.monthlyLimit).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBudgetEditor(BuildContext context) async {
    final categoryProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    if (categoryProvider.categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置分类')));
      return;
    }
    String selectedCategoryId = categoryProvider.categories.first.id;
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final currentBudget = budgetProvider.findByCategoryId(
              selectedCategoryId,
            );
            controller.text = controller.text.isEmpty && currentBudget != null
                ? currentBudget.monthlyLimit.toStringAsFixed(2)
                : controller.text;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设置分类预算',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedCategoryId),
                      initialValue: selectedCategoryId,
                      items: categoryProvider.categories
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setLocalState(() {
                          selectedCategoryId = value;
                          final budget = budgetProvider.findByCategoryId(value);
                          controller.text =
                              budget?.monthlyLimit.toStringAsFixed(2) ?? '';
                        });
                      },
                      decoration: const InputDecoration(labelText: '分类'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '月预算',
                        hintText: '例如 2000',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await budgetProvider.removeBudget(
                                selectedCategoryId,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: const Text('删除预算'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final value = double.tryParse(
                                controller.text.trim(),
                              );
                              if (value == null || value <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('请输入大于 0 的预算金额'),
                                  ),
                                );
                                return;
                              }
                              await budgetProvider.upsertBudget(
                                categoryId: selectedCategoryId,
                                monthlyLimit: value,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: const Text('保存'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Widget _buildInsightsSection(StatsSnapshot snapshot) {
    final insights = _buildInsights(snapshot);
    if (insights.isEmpty) {
      return _buildEmptyChart('积累更多账单后，这里会出现智能洞察');
    }
    return Row(
      children: [
        for (int i = 0; i < insights.length; i++) ...[
          Expanded(child: insights[i]),
          if (i != insights.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  List<Widget> _buildInsights(StatsSnapshot snapshot) {
    final widgets = <Widget>[];

    if (snapshot.expenseDeltaRatio != null) {
      final delta = snapshot.expenseDeltaRatio!;
      final isSaving = delta < 0;
      final amount = (snapshot.previousTotalExpense - snapshot.totalExpense)
          .abs();
      widgets.add(
        _buildInsightCard(
          icon: isSaving ? Icons.savings_outlined : Icons.trending_up,
          tone: isSaving ? _InsightTone.positive : _InsightTone.warning,
          label: isSaving ? '相比上一$_periodLabel节省' : '相比上一$_periodLabel多花',
          value: _privacyAmount(context, amount),
        ),
      );
    }

    if (snapshot.categoryBreakdown.isNotEmpty) {
      final top = snapshot.categoryBreakdown.first;
      widgets.add(
        _buildInsightCard(
          icon: Icons.pie_chart_outline,
          tone: _InsightTone.neutral,
          label: '支出最多',
          value: top.category,
          hint:
              '${_privacyAmount(context, top.amount, decimalDigits: 0)} · ${(top.ratio * 100).toStringAsFixed(0)}%',
        ),
      );
    }

    return widgets;
  }

  Widget _buildInsightCard({
    required IconData icon,
    required _InsightTone tone,
    required String label,
    required String value,
    String? hint,
  }) {
    late final Color bgColor;
    late final Color fgColor;
    switch (tone) {
      case _InsightTone.positive:
        bgColor = AppColors.primaryFixed.withValues(alpha: 0.35);
        fgColor = AppColors.primary;
        break;
      case _InsightTone.warning:
        bgColor = AppColors.tertiaryFixed.withValues(alpha: 0.5);
        fgColor = AppColors.tertiary;
        break;
      case _InsightTone.neutral:
        bgColor = AppColors.surfaceContainer;
        fgColor = AppColors.onSurface;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: fgColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fgColor.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }

  String get _periodLabel => _period.label;

  String _rangeLabel(StatsSnapshot snapshot) {
    switch (_period) {
      case StatsPeriod.week:
        final start = snapshot.rangeStart;
        final end = snapshot.rangeEnd.subtract(const Duration(days: 1));
        return '${_formatDate(start)} ~ ${_formatDate(end)}';
      case StatsPeriod.month:
        return '${snapshot.rangeStart.year} 年 ${snapshot.rangeStart.month} 月';
      case StatsPeriod.year:
        return '${snapshot.rangeStart.year} 年';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _privacyAmount(
    BuildContext context,
    double amount, {
    int decimalDigits = 2,
  }) {
    final enabled = context.select<SecurityProvider, bool>(
      (provider) => provider.privacyModeEnabled,
    );
    if (enabled) {
      return '¥****';
    }
    return '¥${amount.toStringAsFixed(decimalDigits)}';
  }
}

enum _InsightTone { positive, warning, neutral }
