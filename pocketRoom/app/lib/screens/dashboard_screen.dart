// 대시보드 화면 — 앱의 "거실". 월세·전기·가스 카드 3종을 한 화면에 통합 표시합니다.
//
// Design 2.6(DashboardScreen) + Sequence 3.2(방 전환)/3.3(View Dashboard)을 따릅니다:
//   - 로그인하면 RoomProvider 가 그 사용자의 방 목록을 불러옵니다.
//   - 방이 없으면 "방 추가" 안내를, 있으면 현재 방의 카드 3종을 보여줍니다.
//   - 상단 드롭다운으로 방을 전환하면 그 방의 카드만 다시 불러옵니다(방별 데이터 분리).
//   - 카드의 설정 버튼을 누르면 각 설정 화면으로 이동하고, 저장 후 돌아오면 다시 로드합니다.
//
// 전기/가스의 월별 이력은 ExternalProviderStub(현재 더미)로 가져옵니다.
// 나중에 실제 OPM 구현으로 교체해도 이 화면 코드는 그대로 유지됩니다(인터페이스 의존).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill_record.dart';
import '../models/city_gas_card.dart';
import '../models/contract_card.dart';
import '../models/electricity_card.dart';
import '../models/room.dart';
import '../providers/room_provider.dart';
import '../services/alarm_service.dart';
import '../services/auth_service.dart';
import '../services/external_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_gas_card_widget.dart';
import '../widgets/contract_card_widget.dart';
import '../widgets/electricity_card_widget.dart';
import 'add_room_screen.dart';
import 'set_city_gas_card_screen.dart';
import 'set_contract_card_screen.dart';
import 'set_electricity_card_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 빌드가 끝난 직후, 현재 사용자의 방 목록을 한 번 불러옵니다.
    // (build 안에서 직접 호출하면 안 되므로 post-frame 콜백을 씁니다.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        context.read<RoomProvider>().ensureLoaded(user.id);
      }
      // 납부일 알림을 위한 OS 권한을 한 번 요청합니다(웹에서는 통과로 가정).
      context.read<AlarmService>().requestPermission();
    });
  }

  // 방 추가 화면 열기 (Sequence 3.2)
  Future<void> _openAddRoom() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddRoomScreen()),
    );
    // RoomProvider 가 새 방을 현재 방으로 잡고 notify 하므로 따로 처리할 일은 없습니다.
  }

  // 로그아웃: 예약된 알림·방 상태를 비우고 인증을 해제합니다(다른 계정으로 로그인 대비).
  void _logout() {
    context.read<AlarmService>().cancelAll();
    context.read<RoomProvider>().clear();
    context.read<AuthService>().logout();
  }

  // 알림 허용 토글 (켜면 권한 요청, 끄면 예약 전체 취소)
  Future<void> _toggleAlarm() async {
    final alarm = context.read<AlarmService>();
    final turnOn = !alarm.isEnabled;
    if (turnOn) await alarm.requestPermission();
    await alarm.setEnabled(turnOn);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(turnOn ? '납부일 알림을 켰어요.' : '납부일 알림을 껐어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final roomProvider = context.watch<RoomProvider>();
    final alarmEnabled = context.watch<AlarmService>().isEnabled;
    final user = auth.currentUser;
    final currentRoom = roomProvider.currentRoom;

    return Scaffold(
      appBar: AppBar(
        // 방이 있으면 제목 자리에 "방 전환 드롭다운"을, 없으면 앱 이름을 표시합니다.
        title: (currentRoom != null && roomProvider.rooms.isNotEmpty)
            ? _RoomSwitcher(
                rooms: roomProvider.rooms,
                current: currentRoom,
                onChanged: (roomId) =>
                    context.read<RoomProvider>().switchRoom(roomId),
              )
            : const Text('Pocket Room'),
        actions: [
          IconButton(
            icon: Icon(alarmEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined),
            tooltip: alarmEnabled ? '납부일 알림 끄기' : '납부일 알림 켜기',
            onPressed: _toggleAlarm,
          ),
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            tooltip: '방 추가',
            onPressed: _openAddRoom,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(roomProvider, currentRoom, user?.id),
    );
  }

  Widget _buildBody(RoomProvider roomProvider, Room? currentRoom, String? userId) {
    // 방 목록 로딩 중
    if (roomProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 방이 하나도 없는 경우 → 방 추가 안내
    if (currentRoom == null) {
      return _EmptyRooms(onAddRoom: _openAddRoom);
    }
    // 현재 방의 카드 3종을 보여줍니다.
    // key 에 roomId 를 줘서 방이 바뀌면 위젯이 새로 만들어지고 카드도 다시 로드됩니다.
    return _RoomDashboardView(
      key: ValueKey(currentRoom.roomId),
      room: currentRoom,
      userId: userId,
    );
  }
}

// ── 방 전환 드롭다운 (AppBar 제목 자리) ──────────────────────────
class _RoomSwitcher extends StatelessWidget {
  final List<Room> rooms;
  final Room current;
  final ValueChanged<String> onChanged;

  const _RoomSwitcher({
    required this.rooms,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current.roomId,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.expand_more),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
        items: [
          for (final room in rooms)
            DropdownMenuItem(value: room.roomId, child: Text(room.name)),
        ],
        onChanged: (roomId) {
          if (roomId != null) onChanged(roomId);
        },
      ),
    );
  }
}

// ── 방이 없을 때 안내 ───────────────────────────────────────────
class _EmptyRooms extends StatelessWidget {
  final VoidCallback onAddRoom;
  const _EmptyRooms({required this.onAddRoom});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              '아직 등록된 방이 없어요.\n첫 방을 추가해 시작해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddRoom,
              icon: const Icon(Icons.add),
              label: const Text('방 추가하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 한 방의 대시보드(카드 3종) ──────────────────────────────────
// 한 대시보드를 그리는 데 필요한 카드 3종을 묶은 데이터 꾸러미.
class _DashboardData {
  final ContractCard contract;
  final ElectricityCard electricity;
  final CityGasCard cityGas;

  _DashboardData({
    required this.contract,
    required this.electricity,
    required this.cityGas,
  });
}

class _RoomDashboardView extends StatefulWidget {
  final Room room;
  final String? userId;

  const _RoomDashboardView({super.key, required this.room, this.userId});

  @override
  State<_RoomDashboardView> createState() => _RoomDashboardViewState();
}

class _RoomDashboardViewState extends State<_RoomDashboardView> {
  final StorageService _storage = StorageService();
  // 외부 연동(stub) — 전기/가스 요금 이력을 가져옵니다.
  final ExternalProvider _provider = ExternalProviderStub();

  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  // 설정 화면에서 저장하고 돌아왔을 때 다시 로드합니다.
  void _reload() {
    setState(() => _future = _loadDashboard());
  }

  // Sequence 3.3 의 loadDashboard(roomId): DB에서 카드를 불러오고,
  // 연결된 요금 카드는 ExternalProvider(stub)로 당월 요금·이력을 갱신합니다.
  Future<_DashboardData> _loadDashboard() async {
    final roomId = widget.room.roomId;

    // ── 월세 카드: DB에서 로드 (없으면 빈 카드) ──
    final contract = await _storage.getContractCard(roomId) ??
        ContractCard.empty(cardId: 'contract_$roomId', roomId: roomId);

    // ── 전기 카드 ──
    var electricity = await _storage.getElectricityCard(roomId) ??
        ElectricityCard.empty(cardId: 'elec_$roomId', roomId: roomId);
    if (electricity.isLinked) {
      // 연결된 경우에만 요금/이력을 외부 연동(stub)으로 가져옵니다.
      final history = await _provider.fetchBillHistory(
        cardId: electricity.cardId,
        cardType: CardType.electricity,
      );
      final amount = await _provider.fetchCurrentMonthAmount(
        cardId: electricity.cardId,
        cardType: CardType.electricity,
      );
      electricity = electricity.copyWith(
        currentMonthAmountWon: amount,
        currentMonthUsageKwh:
            history.isNotEmpty ? history.first.usageKwh : null,
        history: history,
      );
    }

    // ── 가스 카드 ──
    var cityGas = await _storage.getCityGasCard(roomId) ??
        CityGasCard.empty(cardId: 'gas_$roomId', roomId: roomId);
    if (cityGas.isLinked) {
      final history = await _provider.fetchBillHistory(
        cardId: cityGas.cardId,
        cardType: CardType.cityGas,
      );
      final amount = await _provider.fetchCurrentMonthAmount(
        cardId: cityGas.cardId,
        cardType: CardType.cityGas,
      );
      cityGas = cityGas.copyWith(
        currentMonthAmountWon: amount,
        currentMonthUsageM3: history.isNotEmpty ? history.first.usageM3 : null,
        history: history,
      );
    }

    return _DashboardData(
      contract: contract,
      electricity: electricity,
      cityGas: cityGas,
    );
  }

  // ── 설정 화면 열기 (저장 후 돌아오면 다시 로드) ──────────────
  Future<void> _openSetContract(ContractCard card) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetContractCardScreen(card: card)),
    );
    if (changed == true) _reload();
  }

  Future<void> _openSetElectricity(ElectricityCard card) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetElectricityCardScreen(card: card)),
    );
    if (changed == true) _reload();
  }

  Future<void> _openSetCityGas(CityGasCard card) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetCityGasCardScreen(card: card)),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              '대시보드를 불러오지 못했어요.\n${snapshot.error ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        }

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // 인사말 (현재 방 이름)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                '${widget.userId ?? '게스트'}님의 «${widget.room.name}»',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            ContractCardWidget(
              data: data.contract,
              onSettingPressed: () => _openSetContract(data.contract),
            ),
            const SizedBox(height: 16),
            ElectricityCardWidget(
              data: data.electricity,
              onSettingPressed: () => _openSetElectricity(data.electricity),
            ),
            const SizedBox(height: 16),
            CityGasCardWidget(
              data: data.cityGas,
              onSettingPressed: () => _openSetCityGas(data.cityGas),
            ),
          ],
        );
      },
    );
  }
}
