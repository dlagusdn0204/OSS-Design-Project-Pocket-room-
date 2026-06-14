// 전기요금 카드 위젯 — ElectricityCard(데이터)를 화면에 그리는 "액자"입니다.
//
// 당월 요금/사용량을 보여주고, 아래에 월별 추이 미니 차트(fl_chart)를 그립니다.
// 실제 한전 연동은 stub 이라 더미 이력으로 채워집니다(Design 2.6 / Sequence 3.3).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/electricity_card.dart';
import '../theme/app_theme.dart';
import 'card_icon_badge.dart';
import 'card_menu_button.dart';
import 'link_badge.dart';
import 'mini_trend_chart.dart';

class ElectricityCardWidget extends StatelessWidget {
  final ElectricityCard data;
  final VoidCallback? onSettingPressed;

  const ElectricityCardWidget({
    super.key,
    required this.data,
    this.onSettingPressed,
  });

  String _won(int? won) =>
      won == null ? '-' : '${NumberFormat('#,###').format(won)}원';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────
            Row(
              children: [
                const CardIconBadge(
                  icon: Icons.bolt_outlined,
                  color: AppTheme.electricityColor,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '전기요금',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                // 연결 상태 배지
                LinkBadge(isLinked: data.isLinked),
                CardMenuButton(
                  cardKind: CardKind.electricity,
                  onSettingPressed: onSettingPressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── 당월 요금 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _won(data.currentMonthAmountWon),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (data.currentMonthUsageKwh != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${data.currentMonthUsageKwh!.toStringAsFixed(0)} kWh',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text(
                '월별 요금 추이',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            // ── 미니 차트 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MiniTrendChart(
                history: data.history,
                color: AppTheme.electricityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
