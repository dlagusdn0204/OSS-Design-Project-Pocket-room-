// 도시가스요금 카드 위젯 — CityGasCard(데이터)를 화면에 그리는 "액자"입니다.
//
// 회사명·당월 요금/사용량을 보여주고, 월별 추이 미니 차트(fl_chart)를 그립니다.
// 실제 도시가스 연동은 stub 이라 더미 이력으로 채워집니다(Design 2.6 / Sequence 3.3).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/city_gas_card.dart';
import '../theme/app_theme.dart';
import 'card_icon_badge.dart';
import 'card_menu_button.dart';
import 'link_badge.dart';
import 'mini_trend_chart.dart';

class CityGasCardWidget extends StatelessWidget {
  final CityGasCard data;
  final VoidCallback? onSettingPressed;

  const CityGasCardWidget({
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
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.gasColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '도시가스',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      // 회사명 (선택돼 있으면 표시)
                      if (data.gasCompany != null)
                        Text(
                          data.gasCompany!.displayName,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                LinkBadge(isLinked: data.isLinked),
                CardMenuButton(
                  cardKind: CardKind.cityGas,
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
                  if (data.currentMonthUsageM3 != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${data.currentMonthUsageM3!.toStringAsFixed(0)} m³',
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
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            // ── 미니 차트 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MiniTrendChart(
                history: data.history,
                color: AppTheme.gasColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
