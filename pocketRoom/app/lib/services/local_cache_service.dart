
import 'package:sqflite/sqflite.dart';

import '../models/contract_card.dart';
import '../models/city_gas_card.dart';
import '../models/dashboard_cards.dart';
import '../models/electricity_card.dart';
import 'storage_service.dart';

class LocalCacheService {
  final StorageService _storage;

  LocalCacheService({StorageService? storage})
      : _storage = storage ?? StorageService();

  Future<void> clear() async {
    final Database d = await _storage.db;
    await d.delete('bill_records');
    await d.delete('city_gas_cards');
    await d.delete('electricity_cards');
    await d.delete('contract_cards');
    await d.delete('rooms');
  }

  Future<void> saveCards(String roomId, DashboardCards cards) async {
    await _storage.upsertContractCard(cards.contract);
    await _storage.upsertElectricityCard(cards.electricity);
    await _storage.upsertCityGasCard(cards.cityGas);

    final Database d = await _storage.db;
    await d.delete('bill_records',
        where: 'card_id = ?', whereArgs: [cards.electricity.cardId]);
    await d.delete('bill_records',
        where: 'card_id = ?', whereArgs: [cards.cityGas.cardId]);
    for (final r in cards.electricity.history) {
      await _storage.insertBillRecord(r);
    }
    for (final r in cards.cityGas.history) {
      await _storage.insertBillRecord(r);
    }
  }

  Future<DashboardCards?> loadCards(String roomId) async {
    final contract = await _storage.getContractCard(roomId);
    final elec = await _storage.getElectricityCard(roomId);
    final gas = await _storage.getCityGasCard(roomId);

    if (contract == null && elec == null && gas == null) return null;

    final elecCard =
        elec ?? ElectricityCard.empty(cardId: 'elec_$roomId', roomId: roomId);
    final gasCard =
        gas ?? CityGasCard.empty(cardId: 'gas_$roomId', roomId: roomId);

    final elecHistory = await _storage.getBillRecords(elecCard.cardId);
    final gasHistory = await _storage.getBillRecords(gasCard.cardId);

    return DashboardCards(
      contract: contract ??
          ContractCard.empty(cardId: 'contract_$roomId', roomId: roomId),
      electricity: elecCard.copyWith(history: elecHistory),
      cityGas: gasCard.copyWith(history: gasHistory),
    );
  }
}
