// 외부 연동 인터페이스 + stub 구현
// 한전(KEPCO) / 도시가스 데이터를 가져오는 역할입니다.
// 현재는 더미 데이터를 반환하는 stub만 구현돼 있습니다.
// TODO: OPM 사업자 등록 완료 후 ExternalProviderOpm으로 교체

import '../models/bill_record.dart';

// ── 인터페이스 (콘센트 규격) ──────────────────────────────────────────────────
// 이 규격만 맞으면 stub이든 실제 API든 같은 방식으로 사용할 수 있습니다.

abstract class ExternalProvider {
  /// 외부 계정 인증 시도. 성공이면 true 반환.
  Future<bool> authenticate({
    required String loginId,
    required String loginPassword,
  });

  /// 해당 카드의 최근 12개월 요금 이력을 가져옵니다.
  Future<List<BillRecord>> fetchBillHistory({
    required String cardId,
    required CardType cardType,
  });

  /// 당월 요금을 가져옵니다 (원 단위).
  Future<int?> fetchCurrentMonthAmount({
    required String cardId,
    required CardType cardType,
  });
}

// ── Stub 구현 (더미 데이터 반환) ──────────────────────────────────────────────

class ExternalProviderStub implements ExternalProvider {
  @override
  Future<bool> authenticate({
    required String loginId,
    required String loginPassword,
  }) async {
    // TODO: OPM 연동 시 실제 인증 API 호출로 교체
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션
    return true; // 항상 성공으로 가정
  }

  @override
  Future<List<BillRecord>> fetchBillHistory({
    required String cardId,
    required CardType cardType,
  }) async {
    // TODO: OPM 연동 시 실제 API 호출로 교체
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateDummyHistory(cardId: cardId, cardType: cardType);
  }

  @override
  Future<int?> fetchCurrentMonthAmount({
    required String cardId,
    required CardType cardType,
  }) async {
    // TODO: OPM 연동 시 실제 API 호출로 교체
    await Future.delayed(const Duration(milliseconds: 200));
    return cardType == CardType.electricity ? 32000 : 18500;
  }

  // 그럴듯한 더미 이력 데이터 생성 (최근 6개월)
  List<BillRecord> _generateDummyHistory({
    required String cardId,
    required CardType cardType,
  }) {
    final now = DateTime.now();
    // 전기: 여름·겨울 높고 봄·가을 낮은 패턴 / 가스: 겨울 높은 패턴
    final amounts = cardType == CardType.electricity
        ? [32000, 28500, 24000, 31000, 45000, 52000] // 최근 → 과거
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
