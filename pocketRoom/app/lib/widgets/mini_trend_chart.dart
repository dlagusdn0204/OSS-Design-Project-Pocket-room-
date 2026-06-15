
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/bill_record.dart';
import '../theme/app_theme.dart';

class MiniTrendChart extends StatelessWidget {
  final List<BillRecord> history;
  final Color color;

  const MiniTrendChart({
    super.key,
    required this.history,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '아직 표시할 요금 이력이 없어요',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final byMonth = <int, BillRecord>{};
    for (final r in history) {
      byMonth[r.month] = r;
    }

    final spots = <FlSpot>[
      for (var m = 1; m <= 12; m++)
        if (byMonth.containsKey(m))
          FlSpot((m - 1).toDouble(), byMonth[m]!.amountWon.toDouble()),
    ];

    final amounts = byMonth.values.map((r) => r.amountWon).toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b).toDouble();
    final minAmount = amounts.reduce((a, b) => a < b ? a : b).toDouble();
    final padding = (maxAmount - minAmount) * 0.2 + 1000;

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: (minAmount - padding).clamp(0, double.infinity),
          maxY: maxAmount + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxAmount - minAmount) / 2).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final m = value.toInt() + 1;
                  if (m < 1 || m > 12) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$m',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final m = s.x.toInt() + 1;
                final rec = byMonth[m];
                return LineTooltipItem(
                  '$m월\n${rec != null ? _formatWon(rec.amountWon) : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatWon(int won) {
    final s = won.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }
}
