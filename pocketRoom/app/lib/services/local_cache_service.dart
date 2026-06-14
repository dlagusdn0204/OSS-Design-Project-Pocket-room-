// LocalCacheService — 로컬 SQLite 를 "캐시"로 쓰는 서비스입니다.
//
// 역할 변화(중요):
//   백엔드 서버가 생기기 전(Phase 1)에는 SQLite 가 "진짜 데이터 원본"이었습니다.
//   이제(세션 C-A~)는 서버가 원본이고, SQLite 는 오프라인/로딩 중에 잠깐 보여줄
//   "사본(캐시)" 역할로 강등됩니다(Design 2.9). 그래서 기존 StorageService 의
//   SQLite 코드를 그대로 재사용하되, 의미만 '캐시'로 바꿔 이 서비스로 감쌉니다.
//
// 현재(C-A) 책임:
//   - clear(): 로그아웃 시 캐시된 데이터를 모두 비웁니다(다른 계정으로 로그인 대비).
//
// 다음(C-B) 예정:
//   - saveCards(roomId, cards) / loadCards(roomId):
//     서버 GET /rooms/:id/cards 응답을 캐시에 저장/복원해 오프라인·로딩 중 표시.

import 'package:sqflite/sqflite.dart';

import 'storage_service.dart';

class LocalCacheService {
  final StorageService _storage;

  LocalCacheService({StorageService? storage})
      : _storage = storage ?? StorageService();

  // 캐시 전체 비우기 — 로그아웃 시 호출합니다.
  //   서버가 원본이므로, 캐시는 언제든 안전하게 지울 수 있습니다.
  //   (사용자 계정 정보 users 테이블은 더 이상 캐시 대상이 아니므로 건드리지 않습니다.)
  Future<void> clear() async {
    final Database d = await _storage.db;
    await d.delete('bill_records');
    await d.delete('city_gas_cards');
    await d.delete('electricity_cards');
    await d.delete('contract_cards');
    await d.delete('rooms');
  }

  // TODO(C-B): 서버 카드 응답을 캐시에 저장/복원하는 saveCards/loadCards 추가.
  //   - saveCards(String roomId, List<...> cards)
  //   - Future<List<...>> loadCards(String roomId)
}
