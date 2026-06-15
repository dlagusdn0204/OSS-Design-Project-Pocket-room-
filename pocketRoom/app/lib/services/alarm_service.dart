
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmInfo {
  final String alarmId;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const AlarmInfo({
    required this.alarmId,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}

class AlarmService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true;

  final List<AlarmInfo> _scheduled = [];

  bool get isEnabled => _enabled;
  List<AlarmInfo> get scheduledAlarms => List.unmodifiable(_scheduled);

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
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

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) {
      await cancelAll();
    } else {
      debugPrint('[AlarmService] 알림 허용 켜짐');
    }
    notifyListeners();
  }

  Future<void> schedulePaymentAlarm({
    required String alarmId,
    required String roomName,
    required int paymentDueDay,
  }) async {
    await init();

    if (!_enabled) {
      debugPrint('[AlarmService] 알림이 꺼져 있어 예약을 생략합니다.');
      return;
    }

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
      debugPrint(
          '[AlarmService] (웹: 로그로 대체) 알림 예약됨: ${info.body} → $fireAt');
      notifyListeners();
      return;
    }

    await _plugin.zonedSchedule(
      _notificationId(alarmId),
      info.title,
      info.body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_due',
          '납부일 알림',
          channelDescription: '월세·공과금 납부일이 다가오면 알려드립니다',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    debugPrint('[AlarmService] 알림 예약됨: ${info.body} → $fireAt');
    notifyListeners();
  }

  Future<void> cancelAlarm(String alarmId) async {
    _scheduled.removeWhere((a) => a.alarmId == alarmId);
    if (!kIsWeb) {
      await _plugin.cancel(_notificationId(alarmId));
    }
    debugPrint('[AlarmService] 알림 취소됨: $alarmId');
    notifyListeners();
  }

  Future<void> cancelAll() async {
    _scheduled.clear();
    if (!kIsWeb) {
      await _plugin.cancelAll();
    }
    debugPrint('[AlarmService] 모든 알림 취소됨');
    notifyListeners();
  }


  DateTime _nextFireDate(int dueDay) {
    final now = DateTime.now();
    var fire = DateTime(now.year, now.month, dueDay, 9)
        .subtract(const Duration(days: 3));
    if (!fire.isAfter(now)) {
      fire = DateTime(now.year, now.month + 1, dueDay, 9)
          .subtract(const Duration(days: 3));
    }
    return fire;
  }

  int _notificationId(String alarmId) => alarmId.hashCode & 0x7fffffff;
}
