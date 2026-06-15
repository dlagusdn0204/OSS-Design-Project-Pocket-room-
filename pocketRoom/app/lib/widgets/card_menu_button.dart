
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CardKind { contract, electricity, cityGas }

class CardMenuButton extends StatelessWidget {
  final CardKind cardKind;
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
