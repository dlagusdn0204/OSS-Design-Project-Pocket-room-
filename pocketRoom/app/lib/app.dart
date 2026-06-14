// 앱 루트: MaterialApp 설정 + 첫 화면 결정(AuthGate)
//
// 화면 전환의 큰 줄기는 "이름표(named route)"가 아니라 AuthGate(인증 게이트)가 잡습니다.
// 로그인 상태(AuthService)가 바뀌면 AuthGate 가 로그인 화면 ↔ 대시보드를 자동 전환합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// ── 화면 연결 지도 (작업 #11에서 전체 네비게이션 정리) ──────────────────────────
// 이 앱은 "이름표 라우트(named route)" 대신, 인증 상태(AuthGate)와 Navigator.push 로
// 화면을 연결합니다. 설정 화면들이 대상 카드 객체를 생성자 인자로 받기 때문에,
// 인자 전달이 간단한 직접 push 방식이 더 적합합니다. 전체 흐름은 다음과 같습니다.
//
//   AuthGate (앱 시작 시 자동로그인 분기)
//     ├─ 토큰 없음 → LoginScreen ──push──▶ SignupScreen ──pop──▶ LoginScreen
//     └─ 토큰 있음 → DashboardScreen
//                      ├─ push ▶ AddRoomScreen            (방 추가 후 pop)
//                      ├─ push ▶ SetContractCardScreen    (저장 후 pop(true) → 재로드)
//                      ├─ push ▶ SetElectricityCardScreen (저장 후 pop(true) → 재로드)
//                      └─ push ▶ SetCityGasCardScreen     (저장 후 pop(true) → 재로드)
//
//   로그인/로그아웃 시 AuthGate 가 Login ↔ Dashboard 를 자동 전환합니다(아래 watch 참조).

class PocketRoomApp extends StatelessWidget {
  const PocketRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Room',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 첫 화면은 고정 라우트가 아니라 AuthGate 가 동적으로 결정합니다.
      home: const AuthGate(),
      // ℹ️ 방 추가/카드 설정 화면은 이름표 라우트 대신 Navigator.push 로 직접 엽니다.
      //    (설정 화면이 대상 카드 객체를 생성자 인자로 받기 때문에 직접 전달이 더 간단)
    );
  }
}

// ── AuthGate: 자동로그인 여부에 따라 첫 화면을 고르는 "문지기" ──────
// Sequence 3.1 의 시작점입니다:
//   앱 실행 → checkAutoLogin() → 토큰 있으면 대시보드, 없으면 로그인 화면.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true; // 자동로그인 확인이 끝날 때까지 로딩 표시

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    // read: 한 번만 호출하면 되므로 구독(watch)하지 않고 읽기만 합니다.
    await context.read<AuthService>().checkAutoLogin();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // watch: 로그인 상태가 바뀌면(로그인/로그아웃) 이 부분이 다시 그려져
    // 자동으로 적절한 화면으로 전환됩니다. ← provider 의 핵심 장점.
    final auth = context.watch<AuthService>();
    return auth.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
