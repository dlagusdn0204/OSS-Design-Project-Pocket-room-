// 로컬 DB 서비스 (SQLite 래퍼)
// 일반 데이터(User, Room, Card 정보, BillRecord)를 기기에 저장합니다.
// ⚠️ 민감정보(비밀번호·로그인 ID/PW·토큰)는 절대 여기에 저장하지 마세요.
//    민감정보는 secure_storage.dart를 사용하세요.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/contract_card.dart';
import '../models/electricity_card.dart';
import '../models/city_gas_card.dart';
import '../models/bill_record.dart';

class StorageService {
  static Database? _db;
  static const _dbName = 'pocket_room.db';
  static const _dbVersion = 1;

  // 싱글턴 패턴: 앱 전체에서 DB 연결 하나만 유지
  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  // DB 최초 생성 시 테이블 생성
  Future<void> _createTables(Database db, int version) async {
    // 사용자 테이블 — password_hash만 저장 (평문 비밀번호 금지)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 방 테이블
    await db.execute('''
      CREATE TABLE rooms (
        room_id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id)
      )
    ''');

    // 계약 카드 테이블
    await db.execute('''
      CREATE TABLE contract_cards (
        card_id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        updated_at TEXT,
        monthly_rent_won INTEGER,
        payment_due_day INTEGER,
        bank_account TEXT,
        address TEXT,
        FOREIGN KEY (room_id) REFERENCES rooms(room_id)
      )
    ''');

    // 전기 카드 테이블
    // secure_key_prefix: secure_storage에서 로그인 정보를 꺼낼 때 쓰는 키
    await db.execute('''
      CREATE TABLE electricity_cards (
        card_id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        updated_at TEXT,
        secure_key_prefix TEXT NOT NULL,
        current_month_amount_won INTEGER,
        current_month_usage_kwh REAL,
        is_linked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (room_id) REFERENCES rooms(room_id)
      )
    ''');

    // 도시가스 카드 테이블
    await db.execute('''
      CREATE TABLE city_gas_cards (
        card_id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        updated_at TEXT,
        secure_key_prefix TEXT NOT NULL,
        gas_company TEXT,
        current_month_amount_won INTEGER,
        current_month_usage_m3 REAL,
        is_linked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (room_id) REFERENCES rooms(room_id)
      )
    ''');

    // 요금 이력 테이블
    await db.execute('''
      CREATE TABLE bill_records (
        record_id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        card_type TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount_won INTEGER NOT NULL,
        usage_kwh REAL,
        usage_m3 REAL,
        fetched_at TEXT NOT NULL
      )
    ''');
  }

  // ═══════════════════════════════════════════
  //  User CRUD
  // ═══════════════════════════════════════════

  Future<void> insertUser(User user) async {
    final d = await db;
    await d.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserById(String id) async {
    final d = await db;
    final rows = await d.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<bool> userExists(String id) async {
    final user = await getUserById(id);
    return user != null;
  }

  // ═══════════════════════════════════════════
  //  Room CRUD
  // ═══════════════════════════════════════════

  Future<void> insertRoom(Room room) async {
    final d = await db;
    await d.insert('rooms', room.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Room>> getRoomsByOwner(String ownerId) async {
    final d = await db;
    final rows = await d.query('rooms',
        where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'created_at ASC');
    return rows.map(Room.fromMap).toList();
  }

  Future<void> updateRoom(Room room) async {
    final d = await db;
    await d.update('rooms', room.toMap(),
        where: 'room_id = ?', whereArgs: [room.roomId]);
  }

  Future<void> deleteRoom(String roomId) async {
    final d = await db;
    await d.delete('rooms', where: 'room_id = ?', whereArgs: [roomId]);
  }

  // ═══════════════════════════════════════════
  //  ContractCard CRUD
  // ═══════════════════════════════════════════

  Future<void> upsertContractCard(ContractCard card) async {
    final d = await db;
    await d.insert('contract_cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ContractCard?> getContractCard(String roomId) async {
    final d = await db;
    final rows = await d.query('contract_cards',
        where: 'room_id = ?', whereArgs: [roomId]);
    if (rows.isEmpty) return null;
    return ContractCard.fromMap(rows.first);
  }

  // ═══════════════════════════════════════════
  //  ElectricityCard CRUD
  // ═══════════════════════════════════════════

  Future<void> upsertElectricityCard(ElectricityCard card) async {
    final d = await db;
    await d.insert('electricity_cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ElectricityCard?> getElectricityCard(String roomId) async {
    final d = await db;
    final rows = await d.query('electricity_cards',
        where: 'room_id = ?', whereArgs: [roomId]);
    if (rows.isEmpty) return null;
    return ElectricityCard.fromMap(rows.first);
  }

  // ═══════════════════════════════════════════
  //  CityGasCard CRUD
  // ═══════════════════════════════════════════

  Future<void> upsertCityGasCard(CityGasCard card) async {
    final d = await db;
    await d.insert('city_gas_cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CityGasCard?> getCityGasCard(String roomId) async {
    final d = await db;
    final rows = await d.query('city_gas_cards',
        where: 'room_id = ?', whereArgs: [roomId]);
    if (rows.isEmpty) return null;
    return CityGasCard.fromMap(rows.first);
  }

  // ═══════════════════════════════════════════
  //  BillRecord CRUD
  // ═══════════════════════════════════════════

  Future<void> insertBillRecord(BillRecord record) async {
    final d = await db;
    await d.insert('bill_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 특정 카드의 최근 12개월 이력 조회
  Future<List<BillRecord>> getBillRecords(String cardId,
      {int limit = 12}) async {
    final d = await db;
    final rows = await d.query(
      'bill_records',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'year DESC, month DESC',
      limit: limit,
    );
    return rows.map(BillRecord.fromMap).toList();
  }
}
