
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
  final VoidCallback? onRefreshPressed;
  final bool isRefreshing;

  const CityGasCardWidget({
    super.key,
    required this.data,
    this.onSettingPressed,
    this.onRefreshPressed,
    this.isRefreshing = false,
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
                      Text(
                        '${DateTime.now().month}월 가스요금',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
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
                if (onRefreshPressed != null && data.isLinked)
                  IconButton(
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    color: AppTheme.textSecondary,
                    tooltip: '도시가스요금 갱신',
                    onPressed: isRefreshing ? null : onRefreshPressed,
                  ),
                CardMenuButton(
                  cardKind: CardKind.cityGas,
                  onSettingPressed: onSettingPressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
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
