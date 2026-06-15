
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/contract_card.dart';
import '../providers/room_provider.dart';
import '../services/alarm_service.dart';
import '../services/api_client.dart';
import '../services/contract_scanner.dart';
import '../services/room_api.dart';
import '../theme/app_theme.dart';

class SetContractCardScreen extends StatefulWidget {
  final ContractCard card;

  const SetContractCardScreen({super.key, required this.card});

  @override
  State<SetContractCardScreen> createState() => _SetContractCardScreenState();
}

class _SetContractCardScreenState extends State<SetContractCardScreen> {
  final _rentController = TextEditingController();
  final _accountController = TextEditingController();
  final _addressController = TextEditingController();
  int? _dueDay;

  final RoomApi _roomApi = RoomApi();
  final ContractScanner _scanner = ContractScannerStub();

  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _onScanPressed() async {
    setState(() => _isScanning = true);

    final result = await _scanner.scanFromCamera();

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (!result.success) {
      _showMessage('스캔에 실패했어요. 다시 시도하거나 직접 입력해주세요.');
      return;
    }

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

  Future<void> _onSavePressed() async {
    final rentText = _rentController.text.trim();
    final account = _accountController.text.trim();
    final address = _addressController.text.trim();

    if (rentText.isEmpty && account.isEmpty && address.isEmpty && _dueDay == null) {
      _showMessage('한 가지 이상은 입력해주세요.');
      return;
    }

    final rent = rentText.isEmpty ? null : int.tryParse(rentText);

    setState(() => _isSaving = true);

    final updated = widget.card.copyWith(
      monthlyRentWon: rent,
      paymentDueDay: _dueDay,
      bankAccount: account.isEmpty ? null : account,
      address: address.isEmpty ? null : address,
    );

    try {
      await _roomApi.saveContract(updated.roomId, updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.isNetworkError
          ? '서버에 연결할 수 없어 저장하지 못했어요. 잠시 후 다시 시도해주세요.'
          : '저장에 실패했어요: ${e.message}');
      return;
    }

    if (!mounted) return;

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
    Navigator.of(context).pop(true);
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
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

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

              TextField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: '납부 계좌번호',
                  hintText: '예: 국민 123456-78-901234',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '집 주소',
                  hintText: '경북 경산시 대동 214-1',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 28),

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
