// 앱 진입점 — DB 초기화 후 AuthService(provider)를 앱 전체에 공급하고 실행합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/alarm_service.dart';
import 'services/db_init.dart'; // 플랫폼별 DB 초기화 (웹/네이티브 자동 분기)
import 'providers/room_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 웹(Chrome)에서도 SQLite가 동작하도록 DB 팩토리를 설정합니다.
  // 네이티브(iOS/Android)에서는 아무 일도 하지 않습니다.
  initDbFactory();

  // MultiProvider: 여러 "방송국"을 앱 전체에 한꺼번에 꽂아둡니다.
  //   - AuthService: 로그인 상태
  //   - RoomProvider: 방 목록 / 현재 방
  //   - AlarmService: 납부일 알림 예약 + 알림 허용 토글
  // 이제 어떤 화면에서든 context.read/watch<AuthService>() · <RoomProvider>() · <AlarmService>() 로 접근할 수 있습니다.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => AlarmService()),
      ],
      child: const PocketRoomApp(),
    ),
  );
}
