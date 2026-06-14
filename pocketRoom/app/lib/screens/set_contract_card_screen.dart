// 월세 계약 카드 설정 화면 (UC #8, #9) — 월세·납부일·계좌·주소를 입력/저장합니다.
//
// Design 2.6(SetContractCardScreen) + Sequence 3.4(Set Contract Card flow)를 따릅니다:
//   ① 수동 입력 경로: 칸을 직접 채워 저장
//   ② 스캔 경로: '이미지 스캔하기' → ContractScannerStub(현재 더미) → 칸 자동 채움
//   두 경로 모두 마지막엔 같은 저장 로직(ContractCard 저장)으로 합쳐집니다.
//
// ⚠️ 실제 OCR 인식은 stub 입니다. google_mlkit_text_recognition 활성화 시 교체됩니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 입력 포맷터 (숫자만)
import 'package:provider/provider.dart';

import '../models/contract_card.dart';
import '../providers/room_provider.dart';
import '../services/alarm_service.dart';
import '../services/contract_scanner.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SetContractCardScreen extends StatefulWidget {
  // 설정할 대상 카드 (대시보드에서 넘겨줍니다). 기존 값이 있으면 미리 채워집니다.
  final ContractCard card;

  const SetContractCardScreen({super.key, required this.card});

  @override
  State<SetContractCardScreen> createState() => _SetContractCardScreenState();
}

class _SetContractCardScreenState extends State<SetContractCardScreen> {
  final _rentController = TextEditingController();
  final _accountController = TextEditingController();
  final _addressController = TextEditingController();
  int? _dueDay; // 납부일 (1~31). 드롭다운으로 선택합니다.

  final StorageService _storage = StorageService();
  final ContractScanner _scanner = ContractScannerStub();

  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 기존 카드 값으로 입력칸을 미리 채웁니다.
    final c = widget.card;
    if (c.monthlyRentWon != null) {
      _rentController.text = c.monthlyRentWon.toString();
    }
    _accountController.text = c.bankAccount ?? '';
    _addressController.text = c.address ?? '';
    _dueDay = c.paymentDueDay;
  }

  @override
  void dispose() {
    _rentController.dispose();
    _accountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── 이미지 스캔하기 (Sequence 3.4 스캔 경로) ──────────────────
  Future<void> _onScanPressed() async {
    setState(() => _isScanning = true);

    // 현재는 stub — 더미 계약 정보를 돌려줍니다. (실제 OCR은 나중에)
    final result = await _scanner.scanFromCamera();

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (!result.success) {
      _showMessage('스캔에 실패했어요. 다시 시도하거나 직접 입력해주세요.');
      return;
    }

    // 인식된 값으로 칸을 채웁니다 (사용자가 확인 후 수정 가능).
    setState(() {
      if (result.monthlyRentWon != null) {
        _rentController.text = result.monthlyRentWon.toString();
      }
      if (result.bankAccount != null) _accountController.text = result.bankAccount!;
      if (result.address != null) _addressController.text = result.address!;
      _dueDay = result.paymentDueDay ?? _dueDay;
    });
    _showMessage('스캔된 정보를 채웠어요. 확인 후 저장해주세요.');
  }

  // ── 저장 (Sequence 3.4 setInfo → saveContractCard) ───────────
  Future<void> _onSavePressed() async {
    final rentText = _rentController.text.trim();
    final account = _accountController.text.trim();
    final address = _addressController.text.trim();

    // 최소한의 검증: 모든 칸이 비어 있으면 저장할 의미가 없습니다.
    if (rentText.isEmpty && account.isEmpty && address.isEmpty && _dueDay == null) {
      _showMessage('한 가지 이상은 입력해주세요.');
      return;
    }

    final rent = rentText.isEmpty ? null : int.tryParse(rentText);

    setState(() => _isSaving = true);

    // copyWith 로 입력값을 반영한 새 카드를 만들어 저장합니다.
    // (빈 문자열은 null 로 바꿔 "값 없음"으로 저장)
    final updated = widget.card.copyWith(
      monthlyRentWon: rent,
      paymentDueDay: _dueDay,
      bankAccount: account.isEmpty ? null : account,
      address: address.isEmpty ? null : address,
    );
    await _storage.upsertContractCard(updated);

    if (!mounted) return;

    // ── 납부일 알림 예약/취소 (Sequence 3.5) ──────────────────────
    // 납부일이 있으면 그 날짜 기준으로 알림을 예약하고, 비웠으면 기존 예약을 취소합니다.
    final alarm = context.read<AlarmService>();
    final roomName = context.read<RoomProvider>().currentRoom?.name ?? '내 방';
    if (_dueDay != null) {
      await alarm.schedulePaymentAlarm(
        alarmId: updated.cardId,
        roomName: roomName,
        paymentDueDay: _dueDay!,
      );
    } else {
      await alarm.cancelAlarm(updated.cardId);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage('월세 카드 정보를 저장했어요.');
    Navigator.of(context).pop(true); // true = "변경됨" → 대시보드가 다시 로드
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('월세 카드 설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 이미지 스캔 버튼 (stub) ──────────────────────
              OutlinedButton.icon(
                onPressed: _isScanning ? null : _onScanPressed,
                icon: _isScanning
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(_isScanning ? '스캔 중...' : '계약서 이미지 스캔하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '※ 현재는 데모용으로 예시 값이 채워집니다. (실제 OCR은 추후 지원)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ── 월세 금액 (숫자만) ───────────────────────────
              TextField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '월세 (원)',
                  hintText: '예: 500000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // ── 납부일 (1~31일 드롭다운) ─────────────────────
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: const InputDecoration(
                  labelText: '납부일 (매월)',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                hint: const Text('납부일을 선택하세요'),
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('$day일')),
                ],
                onChanged: (value) => setState(() => _dueDay = value),
              ),
              const SizedBox(height: 14),

              // ── 계좌번호 ─────────────────────────────────────
              TextField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: '납부 계좌번호',
                  hintText: '예: 국민 123456-78-901234',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // ── 집 주소 ──────────────────────────────────────
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '집 주소',
                  hintText: '예: 서울시 노원구 공릉로 123',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 28),

              // ── 저장 버튼 ────────────────────────────────────
              ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
