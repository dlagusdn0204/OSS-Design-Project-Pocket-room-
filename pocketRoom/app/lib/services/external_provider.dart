
import '../models/bill_record.dart';


abstract class ExternalProvider {
  Future<bool> authenticate({
    required String loginId,
    required String loginPassword,
  });

  Future<List<BillRecord>> fetchBillHistory({
    required String cardId,
    required CardType cardType,
  });

  Future<int?> fetchCurrentMonthAmount({
    required String cardId,
    required CardType cardType,
  });
}


class ExternalProviderStub implements ExternalProvider {
  @override
  Future<bool> authenticate({
    required String loginId,
    required String loginPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<List<BillRecord>> fetchBillHistory({
    required String cardId,
    required CardType cardType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateDummyHistory(cardId: cardId, cardType: cardType);
  }

  @override
  Future<int?> fetchCurrentMonthAmount({
    required String cardId,
    required CardType cardType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return cardType == CardType.electricity ? 32000 : 18500;
  }

  List<BillRecord> _generateDummyHistory({
    required String cardId,
    required CardType cardType,
  }) {
    final now = DateTime.now();
    final amounts = cardType == CardType.electricity
        ? [32000, 28500, 24000, 31000, 45000, 52000]
        : [18500, 21000, 35000, 62000, 48000, 22000];

    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return BillRecord(
        recordId: '${cardId}_${date.year}${date.month}',
        cardId: cardId,
        cardType: cardType,
        year: date.year,
        month: date.month,
        amountWon: amounts[i],
        usageKwh: cardType == CardType.electricity ? 200.0 + (i * 15) : null,
        usageM3: cardType == CardType.cityGas ? 18.0 + (i * 5) : null,
        fetchedAt: DateTime.now(),
      );
    });
  }
}
