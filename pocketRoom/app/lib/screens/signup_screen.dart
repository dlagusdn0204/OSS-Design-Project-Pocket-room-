// 회원가입 화면 (UC #1) — 아이디/비밀번호/이메일 입력, 아이디 중복확인 후 가입
//
// Design 2.6(SignupScreen) + Sequence 3.1(신규 회원 가입 분기)을 따릅니다.
// 가입이 끝나면 로그인 화면으로 돌아갑니다(Navigator.pop).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _emailController = TextEditingController();

  // 아이디 중복확인 통과 여부. 아이디를 다시 수정하면 false 로 되돌립니다.
  bool _idChecked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 아이디를 고치면 "중복확인 다시 해야 함" 상태로 초기화
    _idController.addListener(() {
      if (_idChecked) setState(() => _idChecked = false);
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── 아이디 중복확인 ──────────────────────────────────────────
  Future<void> _onCheckDuplicatePressed() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showMessage('아이디를 입력해주세요.');
      return;
    }

    final auth = context.read<AuthService>();
    final isDuplicated = await auth.checkDuplicateId(id);
    if (!mounted) return;

    if (isDuplicated) {
      _showMessage('이미 사용 중인 아이디입니다.');
      setState(() => _idChecked = false);
    } else {
      _showMessage('사용 가능한 아이디입니다.');
      setState(() => _idChecked = true);
    }
  }

  // ── 회원가입 버튼 ────────────────────────────────────────────
  Future<void> _onSignupPressed() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    final pwConfirm = _pwConfirmController.text;
    final email = _emailController.text.trim();

    // 입력 검증
    if (id.isEmpty || pw.isEmpty || email.isEmpty) {
      _showMessage('모든 항목을 입력해주세요.');
      return;
    }
    if (!_idChecked) {
      _showMessage('아이디 중복확인을 해주세요.');
      return;
    }
    if (pw.length < 4) {
      _showMessage('비밀번호는 4자 이상 입력해주세요.');
      return;
    }
    if (pw != pwConfirm) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    final success = await auth.signUp(id: id, password: pw, email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showMessage('회원가입이 완료되었습니다. 로그인해주세요.');
      Navigator.of(context).pop(); // 로그인 화면으로 복귀
    } else {
      // 중복확인 후 사이에 누군가 같은 아이디를 만든 드문 경우
      _showMessage('이미 사용 중인 아이디입니다.');
      setState(() => _idChecked = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 아이디 + 중복확인 ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: '아이디',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onCheckDuplicatePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _idChecked ? AppTheme.secondary : AppTheme.primary,
                      ),
                      child: Text(_idChecked ? '확인됨' : '중복확인'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── 비밀번호 ──
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 (4자 이상)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),

              // ── 비밀번호 확인 ──
              TextField(
                controller: _pwConfirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),

              // ── 이메일 ──
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 28),

              // ── 가입 버튼 ──
              ElevatedButton(
                onPressed: _isLoading ? null : _onSignupPressed,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('가입하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
