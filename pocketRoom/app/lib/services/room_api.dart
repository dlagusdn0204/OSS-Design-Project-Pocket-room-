
import '../models/bill_record.dart';
import '../models/contract_card.dart';
import '../models/city_gas_card.dart';
import '../models/dashboard_cards.dart';
import '../models/electricity_card.dart';
import '../models/room.dart';
import 'api_client.dart';

class RoomApi {
  final ApiClient _api;

  RoomApi({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Room>> fetchRooms(String ownerId) async {
    final res = await _api.get('/rooms');
    final list = (res['rooms'] as List?) ?? const [];
    return [
      for (final r in list) _roomFromServer(ownerId, _asMap(r)),
    ];
  }

  Future<Room> createRoom(String ownerId, String name) async {
    final res = await _api.post('/rooms', body: {'name': name});
    return _roomFromServer(ownerId, _asMap(res['room']));
  }

  Future<DashboardCards> fetchCards(String roomId) async {
    final res = await _api.get('/rooms/$roomId/cards');
    return _parseCards(roomId, (res['cards'] as List?) ?? const []);
  }

  Future<ContractCard> saveContract(String roomId, ContractCard card) async {
    final res = await _api.put('/rooms/$roomId/cards/contract', body: {
      'rentWon': card.monthlyRentWon,
      'accountNumber': card.bankAccount,
      'address': card.address,
      'paymentDueDay': card.paymentDueDay,
    });
    final c = _asMap(res['card']);
    return ContractCard.fromServer(
      roomId: roomId,
      cardId: c['id'].toString(),
      data: _asMap(c['data']),
    );
  }

  Future<ElectricityCard> refreshElectricity(
    String roomId, {
    required String customerNo,
    required int year,
    required int month,
  }) async {
    final res = await _api.post(
      '/rooms/$roomId/cards/electricity/refresh',
      body: {'customerNo': customerNo, 'year': year, 'month': month},
    );
    final c = _asMap(res['card']);
    final cardId = c['id'].toString();
    final history = _billRecords(
      (res['history'] as List?) ?? const [],
      cardId,
      CardType.electricity,
    );
    return ElectricityCard.fromServer(
      roomId: roomId,
      cardId: cardId,
      data: _asMap(c['data']),
      history: history,
    );
  }

  Future<CityGasCard> refreshCityGas(
    String roomId, {
    required String customerNo,
    required int year,
    required int month,
    String? company,
  }) async {
    final res = await _api.post(
      '/rooms/$roomId/cards/cityGas/refresh',
      body: {
        'customerNo': customerNo,
        'year': year,
        'month': month,
        'company': ?company,
      },
    );
    final c = _asMap(res['card']);
    final cardId = c['id'].toString();
    final history = _billRecords(
      (res['history'] as List?) ?? const [],
      cardId,
      CardType.cityGas,
    );
    return CityGasCard.fromServer(
      roomId: roomId,
      cardId: cardId,
      data: _asMap(c['data']),
      history: history,
    );
  }


  Room _roomFromServer(String ownerId, Map<String, dynamic> r) => Room(
        roomId: r['id'].toString(),
        ownerId: ownerId,
        name: r['name'] as String,
        createdAt: r['created_at'] != null
            ? (DateTime.tryParse(r['created_at'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );

  DashboardCards _parseCards(String roomId, List cards) {
    Map<String, dynamic>? findByType(String type) {
      for (final c in cards) {
        final m = _asMap(c);
        if (m['type'] == type) return m;
      }
      return null;
    }

    final cm = findByType('contract');
    final em = findByType('electricity');
    final gm = findByType('cityGas');

    final contractId = cm?['id']?.toString() ?? 'contract_$roomId';
    final elecId = em?['id']?.toString() ?? 'elec_$roomId';
    final gasId = gm?['id']?.toString() ?? 'gas_$roomId';

    final contract = cm != null
        ? ContractCard.fromServer(
            roomId: roomId, cardId: contractId, data: _asMap(cm['data']))
        : ContractCard.empty(cardId: contractId, roomId: roomId);

    final electricity = em != null
        ? ElectricityCard.fromServer(
            roomId: roomId,
            cardId: elecId,
            data: _asMap(em['data']),
            history: _billRecords(
                (em['history'] as List?) ?? const [], elecId, CardType.electricity),
          )
        : ElectricityCard.empty(cardId: elecId, roomId: roomId);

    final cityGas = gm != null
        ? CityGasCard.fromServer(
            roomId: roomId,
            cardId: gasId,
            data: _asMap(gm['data']),
            history: _billRecords(
                (gm['history'] as List?) ?? const [], gasId, CardType.cityGas),
          )
        : CityGasCard.empty(cardId: gasId, roomId: roomId);

    return DashboardCards(
        contract: contract, electricity: electricity, cityGas: cityGas);
  }

  List<BillRecord> _billRecords(List rows, String cardId, CardType type) => [
        for (final row in rows)
          BillRecord.fromServer(cardId: cardId, cardType: type, row: _asMap(row)),
      ];

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}
