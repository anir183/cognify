import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/gamification_state.dart';

class ProgressChart extends ConsumerWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(gamificationProvider).userStats;
    final weeklyXp = userStats.weeklyXp;

    // Ensure we have 7 days of data and reverse it for chronological order (Oldest -> Newest)
    final List<int> rawData = weeklyXp.length >= 7
        ? weeklyXp.take(7).toList()
        : List<int>.filled(7, 0);

    // Backend sends [Today, Yesterday, ...]. We need [6 days ago, ..., Today]
    final List<int> data = rawData.reversed.toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "WEEKLY XP",
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.primaryCyan,
                ),
              ),
              Text(
                "${data.reduce((a, b) => a + b)} XP",
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < 7 && data[index] > 0) {
                          // Calculate date: Today - (6 - index) days
                          // index 6 is Today (0 days ago)
                          // index 0 is 6 days ago
                          final date = DateTime.now().subtract(
                            Duration(days: 6 - index),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${date.day}", // Just the day number
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (index) {
                      return FlSpot(index.toDouble(), data[index].toDouble());
                    }),
                    isCurved: true,
                    color: AppTheme.primaryCyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryCyan.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
