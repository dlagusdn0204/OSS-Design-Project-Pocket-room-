// 방 추가 화면 (UC #3) — 방 이름을 입력해 새 거주지를 등록합니다.
//
// Design 2.6(AddRoomScreen) + Sequence 3.2(Add Room flow)를 따릅니다:
//   이름 입력 → 저장 → RoomProvider 가 방 + 빈 카드 3종 자동 생성 → 새 방의 대시보드로 전환.
//
// 저장 로직 자체는 RoomProvider 가 담당하고, 이 화면은 입력만 받아 위임합니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/room_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('방 이름을 입력해주세요.');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      _showMessage('로그인 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }

    setState(() => _isSaving = true);

    // RoomProvider 가 방 + 빈 카드 3종을 만들고 현재 방으로 전환합니다.
    await context.read<RoomProvider>().addRoom(ownerId: user.id, name: name);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(); // 대시보드로 복귀 (provider 가 새 방을 보여줌)
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('방 추가')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 문구
              const Text(
                '새 방을 추가하면 월세·전기·가스 카드가 빈 상태로 함께 만들어져요.\n'
                '각 카드는 대시보드에서 설정 버튼으로 채울 수 있어요.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // 방 이름 입력
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSavePressed(),
                decoration: const InputDecoration(
                  labelText: '방 이름',
                  hintText: '예: 서울 자취방, 본가, 친구네',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 28),

              // 저장 버튼
              ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('방 만들기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
