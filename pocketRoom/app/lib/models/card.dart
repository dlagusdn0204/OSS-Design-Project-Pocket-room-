// 추상 카드 클래스 — ContractCard, ElectricityCard, CityGasCard의 공통 기반
// "abstract"란: 직접 new Card()로 만들 수 없고, 자식 클래스만 생성 가능합니다.

abstract class BaseCard {
  final String cardId;
  final String roomId;       // 어느 방에 속한 카드인지
  final DateTime? updatedAt; // 마지막 수정 시각

  const BaseCard({
    required this.cardId,
    required this.roomId,
    this.updatedAt,
  });
}
