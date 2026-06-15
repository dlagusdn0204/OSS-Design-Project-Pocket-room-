
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _foundId;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onFindPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('가입 때 사용한 이메일을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _foundId = null;
    });

    final auth = context.read<AuthService>();
    try {
      final id = await auth.findId(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _foundId = id;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.isNetworkError) {
        _showMessage('서버에 연결할 수 없어요. 잠시 후 다시 시도해주세요.');
      } else if (e.statusCode == 404) {
        _showMessage('해당 이메일로 가입된 아이디가 없어요.');
      } else {
        _showMessage('아이디를 찾지 못했어요: ${e.message}');
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('아이디 찾기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '가입 때 사용한 이메일을 입력하면 아이디를 알려드려요.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _onFindPressed(),
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _onFindPressed,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('아이디 찾기'),
              ),

              if (_foundId != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '회원님의 아이디는',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _foundId!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('로그인하러 가기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
