
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill_record.dart';
import '../models/city_gas_card.dart';
import '../models/contract_card.dart';
import '../models/dashboard_cards.dart';
import '../models/electricity_card.dart';
import '../models/room.dart';
import '../providers/room_provider.dart';
import '../services/alarm_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/local_cache_service.dart';
import '../services/room_api.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        context.read<RoomProvider>().ensureLoaded(user.id);
      }
      context.read<AlarmService>().requestPermission();
    });
  }

  Future<void> _openAddRoom() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddRoomScreen()),
    );
  }

  void _logout() {
    context.read<AlarmService>().cancelAll();
    context.read<RoomProvider>().clear();
    context.read<AuthService>().logout();
  }

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
    if (roomProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currentRoom == null) {
      return _EmptyRooms(onAddRoom: _openAddRoom);
    }
    return _RoomDashboardView(
      key: ValueKey(currentRoom.roomId),
      room: currentRoom,
      userId: userId,
    );
  }
}

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

class _RoomDashboardView extends StatefulWidget {
  final Room room;
  final String? userId;

  const _RoomDashboardView({super.key, required this.room, this.userId});

  @override
  State<_RoomDashboardView> createState() => _RoomDashboardViewState();
}

class _RoomDashboardViewState extends State<_RoomDashboardView> {
  final RoomApi _roomApi = RoomApi();
  final LocalCacheService _cache = LocalCacheService();

  late Future<DashboardCards> _future;
  bool _offline = false;
  bool _refreshing = false;
  bool _gasRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  void _reload() {
    setState(() {
      _future = _loadDashboard();
      _refreshing = false;
      _gasRefreshing = false;
    });
  }

  Future<DashboardCards> _loadDashboard() async {
    final roomId = widget.room.roomId;
    try {
      final cards = await _roomApi.fetchCards(roomId);
      await _cache.saveCards(roomId, cards);
      _offline = false;
      return cards;
    } on ApiException {
      final cached = await _cache.loadCards(roomId);
      if (cached != null) {
        _offline = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _refreshElectricity(ElectricityCard card) async {
    final customerNo = card.customerNo;
    if (customerNo == null || customerNo.isEmpty) {
      _showSnack('먼저 전기 카드 설정에서 고객번호를 등록해주세요.');
      return;
    }
    setState(() => _refreshing = true);

    final next = _nextMonth(card.history);
    try {
      await _roomApi.refreshElectricity(
        widget.room.roomId,
        customerNo: customerNo,
        year: next.$1,
        month: next.$2,
      );
      if (!mounted) return;
      _showSnack('전기요금을 갱신했어요 (${next.$2}월).');
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      _showSnack(e.isNetworkError
          ? '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.'
          : '갱신 실패: ${e.message}');
    }
  }

  Future<void> _refreshCityGas(CityGasCard card) async {
    final customerNo = card.customerNo;
    if (customerNo == null || customerNo.isEmpty) {
      _showSnack('먼저 도시가스 카드 설정에서 고객번호를 등록해주세요.');
      return;
    }
    setState(() => _gasRefreshing = true);

    final next = _nextMonth(card.history);
    try {
      await _roomApi.refreshCityGas(
        widget.room.roomId,
        customerNo: customerNo,
        year: next.$1,
        month: next.$2,
        company: card.gasCompany?.name,
      );
      if (!mounted) return;
      _showSnack('도시가스요금을 갱신했어요 (${next.$2}월).');
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _gasRefreshing = false);
      _showSnack(e.isNetworkError
          ? '서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.'
          : '갱신 실패: ${e.message}');
    }
  }

  (int, int) _nextMonth(List<BillRecord> history) {
    if (history.isEmpty) {
      final now = DateTime.now();
      return (now.year, now.month);
    }
    var latest = history.first;
    for (final r in history) {
      if (r.year * 100 + r.month > latest.year * 100 + latest.month) latest = r;
    }
    final next = DateTime(latest.year, latest.month + 1, 1);
    return (next.year, next.month);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

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
    return FutureBuilder<DashboardCards>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _LoadError(error: snapshot.error, onRetry: _reload);
        }

        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_offline) _OfflineBanner(onRetry: _reload),
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
                isRefreshing: _refreshing,
                onRefreshPressed: _offline
                    ? null
                    : () => _refreshElectricity(data.electricity),
                onSettingPressed: () => _openSetElectricity(data.electricity),
              ),
              const SizedBox(height: 16),
              CityGasCardWidget(
                data: data.cityGas,
                isRefreshing: _gasRefreshing,
                onRefreshPressed: _offline
                    ? null
                    : () => _refreshCityGas(data.cityGas),
                onSettingPressed: () => _openSetCityGas(data.cityGas),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 18, color: AppTheme.error),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '오프라인 — 저장된 정보를 표시 중이에요.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final msg = error is ApiException
        ? (error as ApiException).message
        : (error?.toString() ?? '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              '대시보드를 불러오지 못했어요.\n$msg',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
