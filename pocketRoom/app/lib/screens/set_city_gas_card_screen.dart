
import 'package:flutter/material.dart';

import '../models/city_gas_card.dart';
import '../services/api_client.dart';
import '../services/room_api.dart';
import '../theme/app_theme.dart';

class SetCityGasCardScreen extends StatefulWidget {
  final CityGasCard card;

  const SetCityGasCardScreen({super.key, required this.card});

  @override
  State<SetCityGasCardScreen> createState() => _SetCityGasCardScreenState();
}

class _SetCityGasCardScreenState extends State<SetCityGasCardScreen> {
  final _customerController = TextEditingController();
  GasCompany? _company;

  final RoomApi _roomApi = RoomApi();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _company = widget.card.gasCompany;
    if (widget.card.customerNo != null) {
      _customerController.text = widget.card.customerNo!;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    if (_company == null) {
      _showMessage('도시가스 회사를 선택해주세요.');
      return;
    }
    final customerNo = _customerController.text.trim();
    if (customerNo.isEmpty) {
      _showMessage('도시가스 고객번호를 입력해주세요.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    try {
      await _roomApi.refreshCityGas(
        widget.card.roomId,
        customerNo: customerNo,
        year: now.year,
        month: now.month,
        company: _company!.name,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.isNetworkError
          ? '서버에 연결할 수 없어 연동하지 못했어요. 잠시 후 다시 시도해주세요.'
          : '연동에 실패했어요: ${e.message}');
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage('도시가스 카드를 연결하고 이번 달 요금을 불러왔어요.');
    Navigator.of(context).pop(true);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('도시가스 카드 설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<GasCompany>(
                initialValue: _company,
                decoration: const InputDecoration(
                  labelText: '도시가스 회사',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                hint: const Text('회사를 선택하세요'),
                items: [
                  for (final company in GasCompany.values)
                    DropdownMenuItem(
                      value: company,
                      child: Text(company.displayName),
                    ),
                ],
                onChanged: (value) => setState(() => _company = value),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '도시가스 고객번호를 입력하면 해당 번호의 가스요금을 불러옵니다.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              TextField(
                controller: _customerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '도시가스 고객번호',
                  hintText: '예: 12345',
                  prefixIcon: Icon(Icons.tag_outlined),
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
                    : const Text('연결하고 저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
