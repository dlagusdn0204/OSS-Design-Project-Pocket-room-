// 외부 계정(한전·도시가스) 연결 여부를 보여주는 작은 배지.
// 전기/가스 카드 위젯이 공통으로 사용합니다.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LinkBadge extends StatelessWidget {
  final bool isLinked;
  const LinkBadge({super.key, required this.isLinked});

  @override
  Widget build(BuildContext context) {
    final color = isLinked ? AppTheme.secondary : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLinked ? '연결됨' : '미연결',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
