import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_app/theme/app_colors.dart';

class FinancialStatsScreen extends StatefulWidget {
  const FinancialStatsScreen({super.key});

  @override
  State<FinancialStatsScreen> createState() => _FinancialStatsScreenState();
}

class _FinancialStatsScreenState extends State<FinancialStatsScreen> {
  int _selectedPeriodIndex = 0;
  final List<String> _periods = ['周', '月', '年'];

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
                    color: AppColors.primaryFixed,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBshQbsLwXmCDoRkyGi1dtJPTD8YVoRLhCARHmf7w7gOOdMmnBeVKW78LxfSaj6-8WnrHfD_k33h6M74Onv1GEv8_7RdyFTEp5BO_gLOViAUK3ZReoOkgvTI_n8Eg9TdK-x5xf82ITpK08BDzWJYjK-oonA6-6GUfOMNJ0K_cpYVVFXm9KME1X1YBA8ujXC4QJJXdCuXnu52cYR0-iVmw3fEYo2_S7bslrXGdsBCbUBWaXQrmbpt9UMjDNS7BkxhJndxgtsHZ2DN3aK',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '财务',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary, // using emerald-900 equivalent
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildPeriodToggle(),
            const SizedBox(height: 32),
            _buildDonutChartSection(),
            const SizedBox(height: 32),
            _buildSpendingTrendsSection(),
            const SizedBox(height: 32),
            _buildInsightsSection(),
            const SizedBox(height: 80), // Padding for bottom nav
          ],
        ),
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
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriodIndex = index;
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
                          )
                        ],
                      )
                    : null,
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDonutChartSection() {
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
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '支出分布',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 192,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 76,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primaryContainer,
                        value: 40,
                        title: '',
                        radius: 16,
                      ),
                      PieChartSectionData(
                        color: AppColors.primaryFixedDim,
                        value: 25,
                        title: '',
                        radius: 16,
                      ),
                      PieChartSectionData(
                        color: AppColors.tertiaryContainer,
                        value: 20,
                        title: '',
                        radius: 16,
                      ),
                      PieChartSectionData(
                        color: AppColors.tertiaryFixedDim,
                        value: 15,
                        title: '',
                        radius: 16,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '总计',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        '\$2,840',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLegendGrid(),
        ],
      ),
    );
  }

  Widget _buildLegendGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 3,
      children: [
        _buildLegendItem(AppColors.primaryContainer, '住房', '\$1,136 (40%)'),
        _buildLegendItem(AppColors.primaryFixedDim, '餐饮', '\$710 (25%)'),
        _buildLegendItem(AppColors.tertiaryContainer, '交通', '\$568 (20%)'),
        _buildLegendItem(AppColors.tertiaryFixedDim, '其他', '\$426 (15%)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingTrendsSection() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('支出趋势', style: Theme.of(context).textTheme.displayMedium),
                  Text('日均：¥92', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.trending_down, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text('减少12%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 192,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBar(0.4, '一', false),
                _buildBar(0.65, '二', false),
                _buildBar(0.9, '三', true),
                _buildBar(0.55, '四', false),
                _buildBar(0.75, '五', false),
                _buildBar(0.45, '六', false),
                _buildBar(0.3, '日', false),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('今日', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('过往', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label, bool isToday) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: heightFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primaryContainer : AppColors.surfaceContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      boxShadow: isToday
                          ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, -1))]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.shade50, // Approximation of emerald-50
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.primary),
                const SizedBox(height: 8),
                Text('预计可节省', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                Text('¥120.50', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50, // Approximation of rose-50
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                const SizedBox(height: 8),
                Text('支出超预算', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red.shade800)),
                Text('就餐', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.red.shade800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
