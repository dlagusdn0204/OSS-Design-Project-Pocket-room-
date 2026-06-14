// 카드 우측 상단 설정(메뉴) 버튼 — 세 카드 위젯이 공통으로 사용합니다.
//
// Design 2.6 의 CardMenuButton 에 해당합니다.
// 누르면 해당 카드의 설정 화면으로 이동합니다.
// ⚠️ 설정 화면(SetContractCardScreen 등)은 작업 #8·#9에서 만들 예정이라,
//    지금은 onSettingPressed 콜백을 받아 동작을 위임만 합니다(없으면 안내 표시).

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// 어떤 카드의 메뉴인지 구분 (나중에 설정 화면 라우팅 분기에 사용)
enum CardKind { contract, electricity, cityGas }

class CardMenuButton extends StatelessWidget {
  final CardKind cardKind;
  // 설정 버튼을 눌렀을 때 실행할 동작 (작업 #8·#9에서 연결).
  final VoidCallback? onSettingPressed;

  const CardMenuButton({
    super.key,
    required this.cardKind,
    this.onSettingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined, size: 20),
      color: AppTheme.textSecondary,
      tooltip: '카드 설정',
      onPressed: () {
        if (onSettingPressed != null) {
          onSettingPressed!();
        } else {
          // TODO: 작업 #8·#9에서 각 카드 설정 화면으로 이동하도록 교체
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카드 설정 화면은 작업 #8·#9에서 연결됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
