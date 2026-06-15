
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/alarm_service.dart';
import 'services/db_init.dart';
import 'providers/room_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initDbFactory();

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
