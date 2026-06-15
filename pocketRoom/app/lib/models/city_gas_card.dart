
import 'card.dart';
import 'bill_record.dart';

enum GasCompany {
  daesung('대성에너지');

  const GasCompany(this.displayName);
  final String displayName;
}

class CityGasCard extends BaseCard {
  final GasCompany? gasCompany;
  final String secureKeyPrefix;

  final String? customerNo;
  final int? currentMonthAmountWon;
  final double? currentMonthUsageM3;
  final bool isLinked;
  final List<BillRecord> history;

  const CityGasCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    required this.secureKeyPrefix,
    this.gasCompany,
    this.customerNo,
    this.currentMonthAmountWon,
    this.currentMonthUsageM3,
    this.isLinked = false,
    this.history = const [],
  });

  CityGasCard copyWith({
    GasCompany? gasCompany,
    String? customerNo,
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
        customerNo: customerNo ?? this.customerNo,
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
        'customer_no': customerNo,
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
        customerNo: map['customer_no'] as String?,
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

  factory CityGasCard.fromServer({
    required String roomId,
    required String cardId,
    required Map<String, dynamic> data,
    required List<BillRecord> history,
  }) {
    final latest = history.isNotEmpty ? history.last : null;

    GasCompany? company;
    final raw = data['company'];
    if (raw is String) {
      for (final g in GasCompany.values) {
        if (g.name == raw) {
          company = g;
          break;
        }
      }
    }

    return CityGasCard(
      cardId: cardId,
      roomId: roomId,
      updatedAt: DateTime.now(),
      secureKeyPrefix: 'gas_$cardId',
      gasCompany: company,
      customerNo: data['customerNo'] as String?,
      isLinked: data['isLinked'] == true,
      currentMonthAmountWon: latest?.amountWon,
      currentMonthUsageM3: latest?.usageM3,
      history: history,
    );
  }
}
