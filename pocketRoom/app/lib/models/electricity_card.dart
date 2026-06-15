
import 'card.dart';
import 'bill_record.dart';

class ElectricityCard extends BaseCard {
  final String secureKeyPrefix;

  final String? customerNo;
  final int? currentMonthAmountWon;
  final double? currentMonthUsageKwh;
  final bool isLinked;
  final List<BillRecord> history;

  const ElectricityCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    required this.secureKeyPrefix,
    this.customerNo,
    this.currentMonthAmountWon,
    this.currentMonthUsageKwh,
    this.isLinked = false,
    this.history = const [],
  });

  ElectricityCard copyWith({
    String? customerNo,
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
        customerNo: customerNo ?? this.customerNo,
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
        'customer_no': customerNo,
        'current_month_amount_won': currentMonthAmountWon,
        'current_month_usage_kwh': currentMonthUsageKwh,
        'is_linked': isLinked ? 1 : 0,
      };

  factory ElectricityCard.fromMap(Map<String, dynamic> map) => ElectricityCard(
        cardId: map['card_id'] as String,
        roomId: map['room_id'] as String,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        secureKeyPrefix: map['secure_key_prefix'] as String,
        customerNo: map['customer_no'] as String?,
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

  factory ElectricityCard.fromServer({
    required String roomId,
    required String cardId,
    required Map<String, dynamic> data,
    required List<BillRecord> history,
  }) {
    final latest = history.isNotEmpty ? history.last : null;
    return ElectricityCard(
      cardId: cardId,
      roomId: roomId,
      updatedAt: DateTime.now(),
      secureKeyPrefix: 'elec_$cardId',
      customerNo: data['customerNo'] as String?,
      isLinked: data['isLinked'] == true,
      currentMonthAmountWon: latest?.amountWon,
      currentMonthUsageKwh: latest?.usageKwh,
      history: history,
    );
  }
}
