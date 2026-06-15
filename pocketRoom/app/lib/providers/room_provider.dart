
import 'package:flutter/foundation.dart';

import '../models/room.dart';
import '../services/api_client.dart';
import '../services/room_api.dart';
import '../services/storage_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomApi _api;
  final StorageService _cache;

  RoomProvider({RoomApi? api, StorageService? cache})
      : _api = api ?? RoomApi(),
        _cache = cache ?? StorageService();

  List<Room> _rooms = [];
  List<Room> get rooms => List.unmodifiable(_rooms);

  Room? _currentRoom;
  Room? get currentRoom => _currentRoom;

  bool _loading = false;
  bool get isLoading => _loading;

  bool _offline = false;
  bool get isOffline => _offline;

  String? _loadedOwnerId;

  Future<void> loadRooms(String ownerId) async {
    _loading = true;
    notifyListeners();

    try {
      final rooms = await _api.fetchRooms(ownerId);
      _offline = false;
      for (final r in rooms) {
        await _cache.insertRoom(r);
      }
      _rooms = rooms;
    } on ApiException {
      _offline = true;
      _rooms = await _cache.getRoomsByOwner(ownerId);
    }

    _currentRoom = _rooms.isNotEmpty ? _rooms.first : null;
    _loadedOwnerId = ownerId;

    _loading = false;
    notifyListeners();
  }

  Future<void> ensureLoaded(String ownerId) async {
    if (_loadedOwnerId == ownerId) return;
    await loadRooms(ownerId);
  }

  Future<void> refresh(String ownerId) => loadRooms(ownerId);

  Future<Room> addRoom({required String ownerId, required String name}) async {
    final room = await _api.createRoom(ownerId, name);
    await _cache.insertRoom(room);
    _rooms = [..._rooms, room];
    _currentRoom = room;
    _offline = false;
    notifyListeners();
    return room;
  }

  void switchRoom(String roomId) {
    final target = _rooms.where((r) => r.roomId == roomId);
    if (target.isEmpty) return;
    _currentRoom = target.first;
    notifyListeners();
  }

  void clear() {
    _rooms = [];
    _currentRoom = null;
    _loadedOwnerId = null;
    _offline = false;
    notifyListeners();
  }
}
