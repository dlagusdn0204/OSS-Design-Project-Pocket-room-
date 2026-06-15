
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  Future<void> _onResetPressed() async {
    final id = _idController.text.trim();
    final email = _emailController.text.trim();
    final pw = _pwController.text;
    final pwConfirm = _pwConfirmController.text;

    if (id.isEmpty || email.isEmpty || pw.isEmpty) {
      _showMessage('아이디·이메일·새 비밀번호를 모두 입력해주세요.');
      return;
    }
    if (pw.length < 4) {
      _showMessage('새 비밀번호는 4자 이상으로 입력해주세요.');
      return;
    }
    if (pw != pwConfirm) {
      _showMessage('새 비밀번호가 서로 일치하지 않아요.');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    try {
      await auth.resetPassword(id: id, email: email, newPassword: pw);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.isNetworkError) {
        _showMessage('서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      } else {
        _showMessage(e.message);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage('비밀번호를 변경했어요. 새 비밀번호로 로그인해주세요.');
    Navigator.of(context).pop();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '아이디와 가입 이메일이 일치하면 새 비밀번호로 변경할 수 있어요.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '아이디',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '가입 이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _pwConfirmController,
                obscureText: true,
                onSubmitted: (_) => _onResetPressed(),
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _onResetPressed,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('비밀번호 변경'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
