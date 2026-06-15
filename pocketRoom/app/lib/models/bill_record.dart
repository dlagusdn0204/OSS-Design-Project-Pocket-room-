
enum CardType { electricity, cityGas }

class BillRecord {
  final String recordId;
  final String cardId;
  final CardType cardType;
  final int year;
  final int month;
  final int amountWon;
  final double? usageKwh;
  final double? usageM3;
  final DateTime fetchedAt;

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

  factory BillRecord.fromServer({
    required String cardId,
    required CardType cardType,
    required Map<String, dynamic> row,
  }) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return BillRecord(
      recordId:
          (row['id'] ?? '${cardId}_${row['year']}${row['month']}').toString(),
      cardId: cardId,
      cardType: cardType,
      year: (row['year'] as num).toInt(),
      month: (row['month'] as num).toInt(),
      amountWon: (row['amount_won'] as num).toInt(),
      usageKwh:
          cardType == CardType.electricity ? toDouble(row['usage_kwh']) : null,
      usageM3: cardType == CardType.cityGas ? toDouble(row['usage_m3']) : null,
      fetchedAt: row['fetched_at'] != null
          ? (DateTime.tryParse(row['fetched_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'BillRecord($year-$month, $amountWon원)';
}
