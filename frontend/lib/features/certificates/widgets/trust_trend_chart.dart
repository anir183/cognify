import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrustTrendChart extends StatelessWidget {
  const TrustTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock History Data until we have real history endpoint
    final historyData = [
      const FlSpot(0, 65),
      const FlSpot(1, 68),
      const FlSpot(2, 72),
      const FlSpot(3, 70), // slight dip
      const FlSpot(4, 78),
      const FlSpot(5, 82),
      const FlSpot(6, 85),
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text(
                'Trust Trend (7 Days)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Row(
                children: [
                  Icon(Icons.trending_up, color: const Color(0xFF10B981), size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    '+20%',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0: return const Text('Mon', style: TextStyle(color: Colors.white30, fontSize: 10));
                          case 3: return const Text('Wed', style: TextStyle(color: Colors.white30, fontSize: 10));
                          case 6: return const Text('Today', style: TextStyle(color: Colors.white30, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: historyData,
                    isCurved: true,
                    color: const Color(0xFF6366F1),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
