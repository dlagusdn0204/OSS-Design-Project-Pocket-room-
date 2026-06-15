
abstract class BaseCard {
  final String cardId;
  final String roomId;
  final DateTime? updatedAt;

  const BaseCard({
    required this.cardId,
    required this.roomId,
    this.updatedAt,
  });
}
