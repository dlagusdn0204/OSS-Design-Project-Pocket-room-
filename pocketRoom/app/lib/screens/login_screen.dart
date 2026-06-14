// 로그인 화면 (UC #2) — 아이디/비밀번호 입력, 자동로그인 토글, 회원가입 이동
//
// Design 2.6(LoginScreen) + Sequence 3.1 을 따릅니다.
// 로그인 성공 시 화면 이동 코드를 직접 부르지 않습니다. 대신 AuthService 의 상태가
// 바뀌면 AuthGate 가 자동으로 대시보드로 전환합니다 (provider 흐름).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // TextEditingController: 입력칸의 글자를 읽고 제어하는 "리모컨"입니다.
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  bool _autoLoginChecked = false; // 자동로그인 토글 상태
  bool _isLoading = false; // 로그인 처리 중 버튼 비활성화용

  @override
  void dispose() {
    // 화면이 사라질 때 컨트롤러를 정리해 메모리 누수를 막습니다.
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // ── 로그인 버튼 ──────────────────────────────────────────────
  Future<void> _onLoginPressed() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;

    if (id.isEmpty || pw.isEmpty) {
      _showMessage('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    // listen: false → 여기서는 '값을 읽기만' 하고 구독은 하지 않습니다.
    final auth = context.read<AuthService>();
    final success = await auth.login(
      id: id,
      password: pw,
      autoLogin: _autoLoginChecked,
    );

    if (!mounted) return; // 비동기 사이에 화면이 사라졌으면 중단
    setState(() => _isLoading = false);

    if (!success) {
      _showMessage('아이디 또는 비밀번호가 올바르지 않습니다.');
    }
    // 성공 시: 별도 화면 이동 없음. AuthService 가 notifyListeners() 했으므로
    // AuthGate 가 알아서 대시보드로 바꿔줍니다.
  }

  void _onAutoLoginToggled(bool? value) {
    setState(() => _autoLoginChecked = value ?? false);
  }

  void _goToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  // 아이디/비밀번호 찾기 — 현재는 자리만 (추후 구현)
  void _onFindIdPressed() => _showMessage('아이디 찾기는 추후 제공될 예정입니다.');
  void _onFindPasswordPressed() => _showMessage('비밀번호 찾기는 추후 제공될 예정입니다.');

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── 로고 영역 ──
                const Icon(Icons.home_work_outlined,
                    size: 64, color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Pocket Room',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '자취생을 위한 공과금·월세 관리 앱',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 36),

                // ── 아이디 입력 ──
                TextField(
                  controller: _idController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
                TextField(
                  controller: _pwController,
                  obscureText: true, // 비밀번호 가리기
                  onSubmitted: (_) => _onLoginPressed(),
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 자동로그인 토글 ──
                Row(
                  children: [
                    Checkbox(
                      value: _autoLoginChecked,
                      onChanged: _onAutoLoginToggled,
                    ),
                    const Text('자동 로그인'),
                  ],
                ),
                const SizedBox(height: 8),

                // ── 로그인 버튼 ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onLoginPressed,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 12),

                // ── 회원가입 이동 ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _goToSignup,
                    child: const Text('회원가입'),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 아이디/비밀번호 찾기 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: _onFindIdPressed,
                        child: const Text('아이디 찾기')),
                    const Text('·', style: TextStyle(color: AppTheme.textSecondary)),
                    TextButton(
                        onPressed: _onFindPasswordPressed,
                        child: const Text('비밀번호 찾기')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
