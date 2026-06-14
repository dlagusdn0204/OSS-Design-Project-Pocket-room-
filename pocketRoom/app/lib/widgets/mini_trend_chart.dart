// 월별 요금 추이 미니 차트 — 전기/가스 카드에서 공통으로 사용합니다.
//
// fl_chart 의 LineChart 를 카드 안에 들어갈 만한 작은 크기로 감싼 위젯입니다.
// 전기 카드와 가스 카드가 거의 같은 모양의 그래프를 쓰므로, 중복을 줄이려고
// 하나의 위젯으로 분리했습니다. (월/금액 데이터와 색상만 바꿔서 재사용)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/bill_record.dart';
import '../theme/app_theme.dart';

class MiniTrendChart extends StatelessWidget {
  // 그래프에 그릴 월별 이력 (최신 → 과거 순으로 들어와도 내부에서 정렬합니다)
  final List<BillRecord> history;
  // 선·점 색상 (전기=노랑, 가스=연빨강 등 카드 색을 그대로 씁니다)
  final Color color;

  const MiniTrendChart({
    super.key,
    required this.history,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 이력이 없으면 그래프 대신 안내 문구를 보여줍니다.
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

    // 과거 → 최신 순으로 정렬 (그래프는 왼쪽이 과거, 오른쪽이 최신)
    final sorted = [...history]
      ..sort((a, b) => (a.year * 100 + a.month).compareTo(b.year * 100 + b.month));

    // 각 달을 x=0,1,2... 로, 금액(원)을 y 로 매핑합니다.
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].amountWon.toDouble()),
    ];

    final amounts = sorted.map((r) => r.amountWon).toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b).toDouble();
    final minAmount = amounts.reduce((a, b) => a < b ? a : b).toDouble();
    // 위아래로 약간 여백을 줘서 선이 테두리에 붙지 않게 합니다.
    final padding = (maxAmount - minAmount) * 0.2 + 1000;

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sorted.length - 1).toDouble(),
          minY: (minAmount - padding).clamp(0, double.infinity),
          maxY: maxAmount + padding,
          // 격자선: 가로선만 옅게 표시
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxAmount - minAmount) / 2).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          // 테두리 숨김 (미니 차트라 깔끔하게)
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            // 위·오른쪽·왼쪽 눈금은 숨기고, 아래쪽에 "월"만 표시
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${sorted[i].month}월',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 막대(선) 데이터
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              // 선 아래를 옅은 색으로 채워 추이를 강조
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          // 점을 누르면 그 달의 금액을 툴팁으로 표시
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.toInt();
                final rec = sorted[i];
                return LineTooltipItem(
                  '${rec.month}월\n${_formatWon(rec.amountWon)}',
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

  // 간단한 천 단위 콤마 포맷 (intl 의존 없이 툴팁에서만 사용)
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
