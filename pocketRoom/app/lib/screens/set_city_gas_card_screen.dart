// 도시가스 카드 설정 화면 (UC #5) — 회사 선택 + 로그인 정보 입력·검증·저장.
//
// Design 2.6(SetCityGasCardScreen) + Design 4.4(보안 원칙)을 따릅니다.
//
// 🔒 보안 규칙(전기 카드와 동일):
//   로그인 id / pw 는 secure_storage 에만 저장합니다. SQLite 에는 회사명·연결 여부만 저장합니다.
//
// TODO: 도시가스는 전국 단일 사업자가 아니라 지역별로 나뉩니다(서울도시가스/삼천리/인천 등).
//       회사별 실제 연동 방식은 추후 결정됩니다. 지금은 회사 선택 + stub 검증만 합니다.

import 'package:flutter/material.dart';

import '../models/city_gas_card.dart';
import '../services/external_provider.dart';
import '../services/secure_storage.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SetCityGasCardScreen extends StatefulWidget {
  final CityGasCard card;

  const SetCityGasCardScreen({super.key, required this.card});

  @override
  State<SetCityGasCardScreen> createState() => _SetCityGasCardScreenState();
}

class _SetCityGasCardScreenState extends State<SetCityGasCardScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  GasCompany? _company; // 선택한 도시가스 회사

  final SecureStorageService _secure = SecureStorageService();
  final StorageService _storage = StorageService();
  final ExternalProvider _provider = ExternalProviderStub();

  bool _validated = false;
  bool _isValidating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _company = widget.card.gasCompany;
    _loadSavedId();
    _idController.addListener(_resetValidated);
    _pwController.addListener(_resetValidated);
  }

  Future<void> _loadSavedId() async {
    final savedId =
        await _secure.getCityGasLoginId(widget.card.secureKeyPrefix);
    if (mounted && savedId != null) {
      _idController.text = savedId;
    }
  }

  void _resetValidated() {
    if (_validated) setState(() => _validated = false);
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // ── 검증 (stub — 현재 항상 성공) ─────────────────────────────
  Future<void> _onValidatePressed() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    if (_company == null) {
      _showMessage('도시가스 회사를 먼저 선택해주세요.');
      return;
    }
    if (id.isEmpty || pw.isEmpty) {
      _showMessage('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isValidating = true);
    final ok = await _provider.authenticate(loginId: id, loginPassword: pw);
    if (!mounted) return;
    setState(() {
      _isValidating = false;
      _validated = ok;
    });
    _showMessage(ok ? '검증에 성공했어요. 저장할 수 있어요.' : '검증에 실패했어요. 정보를 확인해주세요.');
  }

  // ── 저장 (🔒 id/pw 는 secure_storage 에만) ───────────────────
  Future<void> _onSavePressed() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    if (_company == null) {
      _showMessage('도시가스 회사를 선택해주세요.');
      return;
    }
    if (id.isEmpty || pw.isEmpty) {
      _showMessage('아이디와 비밀번호를 입력해주세요.');
      return;
    }
    if (!_validated) {
      _showMessage('먼저 검증 버튼을 눌러주세요.');
      return;
    }

    setState(() => _isSaving = true);

    // 🔒 로그인 정보는 secure_storage 에만 저장 (SQLite 금지)
    await _secure.saveCityGasCredentials(
      prefix: widget.card.secureKeyPrefix,
      loginId: id,
      loginPassword: pw,
    );

    // SQLite 에는 회사명·연결 여부만 저장 (id/pw 는 절대 넣지 않음)
    final updated = widget.card.copyWith(gasCompany: _company, isLinked: true);
    await _storage.upsertCityGasCard(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage('도시가스 카드를 연결했어요.');
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
              // 회사 선택 드롭다운
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

              // 보안 안내 박스
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '로그인 정보는 기기의 보안 저장소에만 안전하게 보관됩니다. '
                        '서버나 일반 DB에는 저장되지 않아요.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 아이디
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '도시가스 로그인 아이디',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              // 비밀번호
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '도시가스 로그인 비밀번호',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 18),

              // 검증 버튼
              OutlinedButton.icon(
                onPressed: _isValidating ? null : _onValidatePressed,
                icon: _isValidating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_validated
                        ? Icons.check_circle_outline
                        : Icons.verified_outlined),
                label: Text(_isValidating
                    ? '검증 중...'
                    : (_validated ? '검증됨' : '검증하기')),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _validated ? AppTheme.secondary : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    : const Text('연결하고 저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
