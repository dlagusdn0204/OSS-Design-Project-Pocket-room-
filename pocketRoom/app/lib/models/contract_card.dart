
import 'card.dart';

class ContractCard extends BaseCard {
  final int? monthlyRentWon;
  final int? paymentDueDay;
  final String? bankAccount;
  final String? address;

  const ContractCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    this.monthlyRentWon,
    this.paymentDueDay,
    this.bankAccount,
    this.address,
  });

  ContractCard copyWith({
    int? monthlyRentWon,
    int? paymentDueDay,
    String? bankAccount,
    String? address,
  }) =>
      ContractCard(
        cardId: cardId,
        roomId: roomId,
        updatedAt: DateTime.now(),
        monthlyRentWon: monthlyRentWon ?? this.monthlyRentWon,
        paymentDueDay: paymentDueDay ?? this.paymentDueDay,
        bankAccount: bankAccount ?? this.bankAccount,
        address: address ?? this.address,
      );

  bool get isEmpty =>
      monthlyRentWon == null &&
      paymentDueDay == null &&
      bankAccount == null &&
      address == null;

  Map<String, dynamic> toMap() => {
        'card_id': cardId,
        'room_id': roomId,
        'updated_at': updatedAt?.toIso8601String(),
        'monthly_rent_won': monthlyRentWon,
        'payment_due_day': paymentDueDay,
        'bank_account': bankAccount,
        'address': address,
      };

  factory ContractCard.fromMap(Map<String, dynamic> map) => ContractCard(
        cardId: map['card_id'] as String,
        roomId: map['room_id'] as String,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        monthlyRentWon: map['monthly_rent_won'] as int?,
        paymentDueDay: map['payment_due_day'] as int?,
        bankAccount: map['bank_account'] as String?,
        address: map['address'] as String?,
      );

  factory ContractCard.empty({required String cardId, required String roomId}) =>
      ContractCard(cardId: cardId, roomId: roomId);

  factory ContractCard.fromServer({
    required String roomId,
    required String cardId,
    required Map<String, dynamic> data,
  }) =>
      ContractCard(
        cardId: cardId,
        roomId: roomId,
        updatedAt: DateTime.now(),
        monthlyRentWon: (data['rentWon'] as num?)?.toInt(),
        paymentDueDay: (data['paymentDueDay'] as num?)?.toInt(),
        bankAccount: data['accountNumber'] as String?,
        address: data['address'] as String?,
      );
}
