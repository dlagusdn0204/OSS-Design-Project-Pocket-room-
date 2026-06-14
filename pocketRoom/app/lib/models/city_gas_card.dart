// 도시가스 카드 모델 — 가스요금과 회사 정보를 관리합니다
// ⚠️ 로그인 정보는 secure_storage에만 보관 (secureKeyPrefix 참조)

import 'card.dart';
import 'bill_record.dart';

// 지원 도시가스 회사 목록 (현재는 더미, 추후 확장)
enum GasCompany {
  seoul('서울도시가스'),
  samchully('삼천리'),
  incheon('인천도시가스'),
  other('기타');

  const GasCompany(this.displayName);
  final String displayName;
}

class CityGasCard extends BaseCard {
  final GasCompany? gasCompany;         // 도시가스 회사
  final String secureKeyPrefix;         // secure_storage 키 접두사

  final int? currentMonthAmountWon;     // 당월 가스요금 (원)
  final double? currentMonthUsageM3;   // 당월 사용량 (m³)
  final bool isLinked;                  // 가스사 계정 연결 여부
  final List<BillRecord> history;       // 월별 이력

  const CityGasCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    required this.secureKeyPrefix,
    this.gasCompany,
    this.currentMonthAmountWon,
    this.currentMonthUsageM3,
    this.isLinked = false,
    this.history = const [],
  });

  CityGasCard copyWith({
    GasCompany? gasCompany,
    int? currentMonthAmountWon,
    double? currentMonthUsageM3,
    bool? isLinked,
    List<BillRecord>? history,
  }) =>
      CityGasCard(
        cardId: cardId,
        roomId: roomId,
        updatedAt: DateTime.now(),
        secureKeyPrefix: secureKeyPrefix,
        gasCompany: gasCompany ?? this.gasCompany,
        currentMonthAmountWon:
            currentMonthAmountWon ?? this.currentMonthAmountWon,
        currentMonthUsageM3: currentMonthUsageM3 ?? this.currentMonthUsageM3,
        isLinked: isLinked ?? this.isLinked,
        history: history ?? this.history,
      );

  Map<String, dynamic> toMap() => {
        'card_id': cardId,
        'room_id': roomId,
        'updated_at': updatedAt?.toIso8601String(),
        'secure_key_prefix': secureKeyPrefix,
        'gas_company': gasCompany?.name,
        'current_month_amount_won': currentMonthAmountWon,
        'current_month_usage_m3': currentMonthUsageM3,
        'is_linked': isLinked ? 1 : 0,
      };

  factory CityGasCard.fromMap(Map<String, dynamic> map) => CityGasCard(
        cardId: map['card_id'] as String,
        roomId: map['room_id'] as String,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        secureKeyPrefix: map['secure_key_prefix'] as String,
        gasCompany: map['gas_company'] != null
            ? GasCompany.values.byName(map['gas_company'] as String)
            : null,
        currentMonthAmountWon: map['current_month_amount_won'] as int?,
        currentMonthUsageM3: map['current_month_usage_m3'] as double?,
        isLinked: (map['is_linked'] as int? ?? 0) == 1,
      );

  factory CityGasCard.empty({required String cardId, required String roomId}) =>
      CityGasCard(
        cardId: cardId,
        roomId: roomId,
        secureKeyPrefix: 'gas_$cardId',
      );
}
