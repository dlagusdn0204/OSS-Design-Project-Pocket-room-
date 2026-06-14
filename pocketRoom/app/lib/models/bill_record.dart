// 월별 요금 이력 모델 — 전기/가스 카드의 월별 추이 그래프에 사용됩니다

// 카드 종류 구분자
enum CardType { electricity, cityGas }

class BillRecord {
  final String recordId;
  final String cardId;       // ElectricityCard.cardId 또는 CityGasCard.cardId
  final CardType cardType;
  final int year;
  final int month;
  final int amountWon;       // 요금 (원 단위 정수, 소수점 오차 방지)
  final double? usageKwh;    // 전기 사용량 kWh (가스는 null)
  final double? usageM3;     // 가스 사용량 m³ (전기는 null)
  final DateTime fetchedAt;  // 데이터 가져온 시각

  const BillRecord({
    required this.recordId,
    required this.cardId,
    required this.cardType,
    required this.year,
    required this.month,
    required this.amountWon,
    this.usageKwh,
    this.usageM3,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() => {
        'record_id': recordId,
        'card_id': cardId,
        'card_type': cardType.name,
        'year': year,
        'month': month,
        'amount_won': amountWon,
        'usage_kwh': usageKwh,
        'usage_m3': usageM3,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  factory BillRecord.fromMap(Map<String, dynamic> map) => BillRecord(
        recordId: map['record_id'] as String,
        cardId: map['card_id'] as String,
        cardType: CardType.values.byName(map['card_type'] as String),
        year: map['year'] as int,
        month: map['month'] as int,
        amountWon: map['amount_won'] as int,
        usageKwh: map['usage_kwh'] as double?,
        usageM3: map['usage_m3'] as double?,
        fetchedAt: DateTime.parse(map['fetched_at'] as String),
      );

  @override
  String toString() => 'BillRecord($year-$month, $amountWon원)';
}
