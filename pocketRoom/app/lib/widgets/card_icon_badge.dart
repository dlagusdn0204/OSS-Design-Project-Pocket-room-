// 카드 좌측 상단의 둥근 아이콘 배지 — 세 카드 위젯이 공통으로 사용합니다.
// (모양을 통일하려고 작은 위젯 하나로 분리했습니다.)

import 'package:flutter/material.dart';

class CardIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const CardIconBadge({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
