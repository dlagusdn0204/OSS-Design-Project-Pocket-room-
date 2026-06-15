
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
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

  bool _idChecked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _onCheckDuplicatePressed() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showMessage('아이디를 입력해주세요.');
      return;
    }

    final auth = context.read<AuthService>();
    try {
      final isDuplicated = await auth.checkDuplicateId(id);
      if (!mounted) return;

      if (isDuplicated) {
        _showMessage('이미 사용 중인 아이디입니다.');
        setState(() => _idChecked = false);
      } else {
        _showMessage('사용 가능한 아이디입니다.');
        setState(() => _idChecked = true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _idChecked = false);
      _showMessage(e.isNetworkError
          ? '서버에 연결할 수 없어 중복확인을 못 했어요. 잠시 후 다시 시도해주세요.'
          : '아이디를 확인하지 못했어요: ${e.message}');
    }
  }

  Future<void> _onSignupPressed() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    final pwConfirm = _pwConfirmController.text;
    final email = _emailController.text.trim();

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
      Navigator.of(context).pop();
    } else {
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

              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 (4자 이상)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _pwConfirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 28),

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
