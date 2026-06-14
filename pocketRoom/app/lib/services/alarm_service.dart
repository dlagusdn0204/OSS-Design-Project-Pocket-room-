// 납부일 알림 서비스 (UC #14) — 계약 카드의 납부일을 기준으로 로컬 푸시 알림을 예약합니다.
//
// Design 2.7(AlarmService) + Sequence 3.5(Billing alarm flow)를 따릅니다:
//   카드 저장/갱신 → schedule(card, dueDay) → OS에 로컬 알림 등록 → 납부일 D-3에 푸시.
//
// 📡 provider 개념: AlarmService 도 ChangeNotifier("방송국")입니다.
//   알림 허용 토글(setEnabled)이 바뀌면 notifyListeners() 로 화면(대시보드 종 아이콘)에 알립니다.
//
// ⚠️ 웹(Chrome)에서는 로컬 알림 플러그인이 동작하지 않습니다 → 콘솔 로그(debugPrint)로 대체합니다.
//    실제 푸시는 iOS/Android 실기기에서만 동작합니다. // TODO: iOS/Android 실기기 검증 필요.

import 'package:flutter/foundation.dart'; // kIsWeb, ChangeNotifier, debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ── 알림 예약 1건의 정보 (메모리에 기록해 두고 디버그/화면 표시에 활용) ──────────────
class AlarmInfo {
  final String alarmId; // 알림 고유 ID (취소 시 사용). 보통 "카드ID" 를 그대로 씁니다.
  final String title;
  final String body;
  final DateTime scheduledAt; // 실제 푸시가 뜰 예정 시각

  const AlarmInfo({
    required this.alarmId,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}

class AlarmService extends ChangeNotifier {
  // flutter_local_notifications 플러그인 인스턴스 (네이티브에서만 실제 동작)
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true; // 알림 허용 여부(토글). 기본값 켜짐.
  // TODO: 토글 값을 기기에 저장해 앱 재시작 후에도 유지하도록 개선 가능(현재는 세션 동안만 유지).

  // 현재 예약돼 있는 알림 목록(메모리). 웹에서도 "예약됨"을 확인하는 용도로 씁니다.
  final List<AlarmInfo> _scheduled = [];

  bool get isEnabled => _enabled;
  List<AlarmInfo> get scheduledAlarms => List.unmodifiable(_scheduled);

  // ── 초기화 ───────────────────────────────────────────────────────────────────
  // 앱 시작 시 한 번, 또는 첫 예약 직전에 호출합니다(여러 번 불러도 안전).
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      // 웹은 플러그인 미지원 → 초기화할 것 없이 로그 모드로만 동작합니다.
      _initialized = true;
      return;
    }

    // 예약 시각을 정확히 계산하려면 타임존이 필요합니다(한국 기준).
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    // TODO: 기기의 실제 타임존을 자동 감지하도록 개선 가능.

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  // ── OS 알림 권한 요청 (iOS / Android 13+) ────────────────────────────────────
  Future<bool> requestPermission() async {
    if (kIsWeb) return true; // 웹은 권한 개념 없이 통과로 가정
    await init();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  // ── 알림 허용 토글 ───────────────────────────────────────────────────────────
  // 끄면 예약된 알림을 모두 취소합니다. (다시 켜면 카드 저장 시 재예약)
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) {
      await cancelAll();
    } else {
      debugPrint('[AlarmService] 알림 허용 켜짐');
    }
    notifyListeners();
  }

  // ── 납부일 알림 예약 (Sequence 3.5) ─────────────────────────────────────────
  // 계약 카드 저장/갱신 시 호출합니다. 납부일(매월 dueDay) 3일 전 오전 9시에 알립니다.
  Future<void> schedulePaymentAlarm({
    required String alarmId, // 보통 계약 카드의 cardId
    required String roomName,
    required int paymentDueDay, // 1~31
  }) async {
    await init();

    if (!_enabled) {
      debugPrint('[AlarmService] 알림이 꺼져 있어 예약을 생략합니다.');
      return;
    }

    // 같은 카드의 기존 예약은 지우고 다시 잡습니다(중복 방지).
    await cancelAlarm(alarmId);

    final fireAt = _nextFireDate(paymentDueDay);
    final info = AlarmInfo(
      alarmId: alarmId,
      title: '납부일 알림',
      body: '$roomName 월세 납부일이 3일 후예요 (매월 $paymentDueDay일)',
      scheduledAt: fireAt,
    );
    _scheduled.add(info);

    if (kIsWeb) {
      // 웹: 실제 예약 대신 콘솔 로그로 "예약됨"을 확인합니다.
      debugPrint(
          '[AlarmService] (웹: 로그로 대체) 알림 예약됨: ${info.body} → $fireAt');
      notifyListeners();
      return;
    }

    // 네이티브: OS에 로컬 알림을 등록합니다. // TODO: iOS/Android 실기기 검증 필요.
    await _plugin.zonedSchedule(
      _notificationId(alarmId),
      info.title,
      info.body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_due', // 채널 ID
          '납부일 알림', // 채널 이름
          channelDescription: '월세·공과금 납부일이 다가오면 알려드립니다',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // 정확 알람은 Android 12+에서 별도 권한이 필요하므로 입문 단계에선 inexact 사용.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // 매월 같은 날짜·시각에 반복.
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    debugPrint('[AlarmService] 알림 예약됨: ${info.body} → $fireAt');
    notifyListeners();
  }

  // ── 알림 취소 ────────────────────────────────────────────────────────────────
  Future<void> cancelAlarm(String alarmId) async {
    _scheduled.removeWhere((a) => a.alarmId == alarmId);
    if (!kIsWeb) {
      await _plugin.cancel(_notificationId(alarmId));
    }
    debugPrint('[AlarmService] 알림 취소됨: $alarmId');
    notifyListeners();
  }

  // 모든 예약 취소 (토글 끌 때 / 로그아웃 시)
  Future<void> cancelAll() async {
    _scheduled.clear();
    if (!kIsWeb) {
      await _plugin.cancelAll();
    }
    debugPrint('[AlarmService] 모든 알림 취소됨');
    notifyListeners();
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────────────────────────

  // 다음 알림 시각 = (이번 달 납부일 - 3일) 오전 9시. 이미 지났으면 다음 달.
  DateTime _nextFireDate(int dueDay) {
    final now = DateTime.now();
    var fire = DateTime(now.year, now.month, dueDay, 9)
        .subtract(const Duration(days: 3));
    if (!fire.isAfter(now)) {
      // 이번 달 시점이 이미 지났으면 다음 달로 (month+1 은 Dart 가 알아서 연도 넘김)
      fire = DateTime(now.year, now.month + 1, dueDay, 9)
          .subtract(const Duration(days: 3));
    }
    return fire;
  }

  // 문자열 alarmId → 알림 플러그인이 요구하는 32비트 양의 정수 ID로 변환.
  int _notificationId(String alarmId) => alarmId.hashCode & 0x7fffffff;
}
