
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/contract_card.dart';
import '../theme/app_theme.dart';
import 'card_icon_badge.dart';
import 'card_menu_button.dart';

class ContractCardWidget extends StatelessWidget {
  final ContractCard data;
  final VoidCallback? onSettingPressed;

  const ContractCardWidget({
    super.key,
    required this.data,
    this.onSettingPressed,
  });

  String _won(int? won) =>
      won == null ? '-' : '${NumberFormat('#,###').format(won)}원';

  void _copy(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 복사됨: $value'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
                  icon: Icons.home_outlined,
                  color: AppTheme.contractColor,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '월세 / 계약',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                CardMenuButton(
                  cardKind: CardKind.contract,
                  onSettingPressed: onSettingPressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: Text(
                  '아직 계약 정보가 없어요. 설정에서 월세·계좌·주소를 입력해 주세요.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _won(data.monthlyRentWon),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (data.paymentDueDay != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '매월 ${data.paymentDueDay}일 납부',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CopyRow(
                label: '계좌번호',
                value: data.bankAccount ?? '-',
                onCopy: () => _copy(context, '계좌번호', data.bankAccount),
              ),
              const SizedBox(height: 10),
              _CopyRow(
                label: '집 주소',
                value: data.address ?? '-',
                onCopy: () => _copy(context, '집 주소', data.address),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18),
          color: AppTheme.primary,
          tooltip: '$label 복사',
          visualDensity: VisualDensity.compact,
          onPressed: value == '-' ? null : onCopy,
        ),
      ],
    );
  }
}

