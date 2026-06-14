// 방(Room) 상태 관리 provider — 현재 사용자의 방 목록과 "지금 보고 있는 방"을 관리합니다.
//
// 📡 provider 개념 복습 (입문용):
//   RoomProvider 도 AuthService 처럼 ChangeNotifier("방송국")입니다.
//   방을 추가하거나(addRoom) 방을 전환하면(switchRoom) 상태가 바뀌고,
//   notifyListeners() 로 "바뀌었다!"고 방송하면 대시보드가 스스로 다시 그려집니다.
//
// Design 2.6(DashboardScreen.switchRoom/onAddRoomPressed) + Sequence 3.2(Add Room)를 따릅니다.
// 방을 새로 만들면 그 방의 빈 카드 3종(월세·전기·가스)도 함께 자동 생성합니다.

import 'package:flutter/foundation.dart'; // ChangeNotifier

import '../models/room.dart';
import '../models/contract_card.dart';
import '../models/electricity_card.dart';
import '../models/city_gas_card.dart';
import '../services/storage_service.dart';

class RoomProvider extends ChangeNotifier {
  final StorageService _storage;

  // 테스트 시 다른 StorageService 를 끼워 넣을 수 있게 했습니다.
  // (StorageService 는 내부적으로 DB 연결 하나를 공유하므로 새로 만들어도 안전합니다.)
  RoomProvider({StorageService? storage})
      : _storage = storage ?? StorageService();

  // ── 상태 ─────────────────────────────────────────────────────
  List<Room> _rooms = [];
  List<Room> get rooms => List.unmodifiable(_rooms);

  Room? _currentRoom; // 지금 대시보드에 보이는 방. null 이면 방이 하나도 없는 상태.
  Room? get currentRoom => _currentRoom;

  bool _loading = false;
  bool get isLoading => _loading;

  // 어떤 사용자의 방 목록을 불러와 뒀는지 기억 → 같은 사용자면 다시 안 불러옵니다.
  String? _loadedOwnerId;

  // ── 방 목록 불러오기 ─────────────────────────────────────────
  // 로그인 직후 한 번 호출합니다. 첫 번째 방을 현재 방으로 잡습니다.
  Future<void> loadRooms(String ownerId) async {
    _loading = true;
    notifyListeners();

    _rooms = await _storage.getRoomsByOwner(ownerId);
    _currentRoom = _rooms.isNotEmpty ? _rooms.first : null;
    _loadedOwnerId = ownerId;

    _loading = false;
    notifyListeners();
  }

  // 아직 이 사용자의 방을 안 불러왔을 때만 불러옵니다 (대시보드 진입 시 사용).
  Future<void> ensureLoaded(String ownerId) async {
    if (_loadedOwnerId == ownerId) return;
    await loadRooms(ownerId);
  }

  // ── 방 추가 (UC #3, Sequence 3.2) ────────────────────────────
  // 방을 만들면 빈 카드 3종(월세·전기·가스)도 함께 생성해 DB에 저장합니다.
  Future<Room> addRoom({required String ownerId, required String name}) async {
    // 간단한 고유 ID — 시간(밀리초)으로 만듭니다. (uuid 패키지 없이 충분)
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

    final room = Room(
      roomId: roomId,
      ownerId: ownerId,
      name: name,
      createdAt: DateTime.now(),
    );
    await _storage.insertRoom(room);

    // 빈 카드 3종 자동 생성 (내용은 이후 각 설정 화면에서 채웁니다)
    await _storage.upsertContractCard(
      ContractCard.empty(cardId: 'contract_$roomId', roomId: roomId),
    );
    await _storage.upsertElectricityCard(
      ElectricityCard.empty(cardId: 'elec_$roomId', roomId: roomId),
    );
    await _storage.upsertCityGasCard(
      CityGasCard.empty(cardId: 'gas_$roomId', roomId: roomId),
    );

    _rooms.add(room);
    _currentRoom = room; // 새로 만든 방으로 바로 전환
    notifyListeners();
    return room;
  }

  // ── 방 전환 ──────────────────────────────────────────────────
  void switchRoom(String roomId) {
    final target = _rooms.where((r) => r.roomId == roomId);
    if (target.isEmpty) return;
    _currentRoom = target.first;
    notifyListeners();
  }

  // ── 로그아웃 시 비우기 ───────────────────────────────────────
  void clear() {
    _rooms = [];
    _currentRoom = null;
    _loadedOwnerId = null;
    notifyListeners();
  }
}
