import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/gamification_state.dart';

class MasteryPieChart extends ConsumerWidget {
  const MasteryPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(gamificationProvider).userStats;
    final categoryStats = userStats.categoryStats;

    // Calculate total for percentage
    final total = categoryStats.values.fold(0, (sum, val) => sum + val);

    // Map to sections
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    final colors = [
      AppTheme.primaryCyan,
      AppTheme.accentPurple,
      const Color(0xFF00FF7F),
      AppTheme.accentPink,
      Colors.orange,
    ];

    int index = 0;
    categoryStats.forEach((key, value) {
      final color = colors[index % colors.length];
      final percentage = total > 0 ? (value / total * 100).round() : 0;

      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          title: '$percentage%',
          color: color,
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(_legendItem(key, color));
      index++;
    });

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: '',
          color: AppTheme.textGrey.withOpacity(0.2),
          radius: 40,
        ),
      );
      legendItems.add(
        const Text("No data yet", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      height: 240, // Increased height for title
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MOST TIME SPENT",
            style: AppTheme.labelLarge.copyWith(color: AppTheme.accentPurple),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendItems,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
