// 전기요금 카드 모델 — 한전 연동 정보와 당월 요금을 관리합니다
// ⚠️ 로그인 정보(loginId, loginPassword)는 이 모델에 저장하지 않습니다.
//    secure_storage에만 보관하고, 여기엔 "secure_storage 키"만 저장합니다.

import 'card.dart';
import 'bill_record.dart';

class ElectricityCard extends BaseCard {
  // secure_storage에서 로그인 정보를 꺼낼 때 쓰는 키 (실제 id/pw 아님)
  final String secureKeyPrefix; // 예: "elec_${cardId}"

  final int? currentMonthAmountWon; // 당월 전기요금 (원)
  final double? currentMonthUsageKwh; // 당월 사용량 (kWh)
  final bool isLinked;               // 한전 계정 연결 여부
  final List<BillRecord> history;    // 최근 6~12개월 이력 (그래프용)

  const ElectricityCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    required this.secureKeyPrefix,
    this.currentMonthAmountWon,
    this.currentMonthUsageKwh,
    this.isLinked = false,
    this.history = const [],
  });

  ElectricityCard copyWith({
    int? currentMonthAmountWon,
    double? currentMonthUsageKwh,
    bool? isLinked,
    List<BillRecord>? history,
  }) =>
      ElectricityCard(
        cardId: cardId,
        roomId: roomId,
        updatedAt: DateTime.now(),
        secureKeyPrefix: secureKeyPrefix,
        currentMonthAmountWon:
            currentMonthAmountWon ?? this.currentMonthAmountWon,
        currentMonthUsageKwh:
            currentMonthUsageKwh ?? this.currentMonthUsageKwh,
        isLinked: isLinked ?? this.isLinked,
        history: history ?? this.history,
      );

  Map<String, dynamic> toMap() => {
        'card_id': cardId,
        'room_id': roomId,
        'updated_at': updatedAt?.toIso8601String(),
        'secure_key_prefix': secureKeyPrefix,
        'current_month_amount_won': currentMonthAmountWon,
        'current_month_usage_kwh': currentMonthUsageKwh,
        'is_linked': isLinked ? 1 : 0,
        // history는 별도 bill_records 테이블에 저장
      };

  factory ElectricityCard.fromMap(Map<String, dynamic> map) => ElectricityCard(
        cardId: map['card_id'] as String,
        roomId: map['room_id'] as String,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        secureKeyPrefix: map['secure_key_prefix'] as String,
        currentMonthAmountWon: map['current_month_amount_won'] as int?,
        currentMonthUsageKwh: map['current_month_usage_kwh'] as double?,
        isLinked: (map['is_linked'] as int? ?? 0) == 1,
      );

  factory ElectricityCard.empty({required String cardId, required String roomId}) =>
      ElectricityCard(
        cardId: cardId,
        roomId: roomId,
        secureKeyPrefix: 'elec_$cardId',
      );
}
