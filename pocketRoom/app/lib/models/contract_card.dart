// 월세 계약 카드 모델 — 월세/납부일/계좌/주소 정보를 저장합니다

import 'card.dart';

class ContractCard extends BaseCard {
  final int? monthlyRentWon;     // 월세 금액 (원 단위)
  final int? paymentDueDay;      // 납부일 (1~31)
  final String? bankAccount;     // 납부 계좌번호
  final String? address;         // 집 주소

  const ContractCard({
    required super.cardId,
    required super.roomId,
    super.updatedAt,
    this.monthlyRentWon,
    this.paymentDueDay,
    this.bankAccount,
    this.address,
  });

  // 일부 필드만 바꾼 복사본 반환
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

  // 빈 카드 생성 (방 생성 시 자동으로 만들어짐)
  factory ContractCard.empty({required String cardId, required String roomId}) =>
      ContractCard(cardId: cardId, roomId: roomId);
}
