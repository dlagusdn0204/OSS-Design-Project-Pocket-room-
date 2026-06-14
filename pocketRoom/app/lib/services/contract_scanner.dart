// 계약서 OCR 인터페이스 + stub 구현
// 계약서 이미지를 스캔해서 월세·주소 등을 자동으로 채워주는 역할입니다.
// TODO: google_mlkit_text_recognition 활성화 후 ContractScannerMlKit으로 교체

import '../models/contract_card.dart';

// ── 스캔 결과 데이터 클래스 ────────────────────────────────────────────────────

class ScanResult {
  final int? monthlyRentWon;
  final int? paymentDueDay;
  final String? bankAccount;
  final String? address;
  final bool success;
  final String? errorMessage;

  const ScanResult({
    this.monthlyRentWon,
    this.paymentDueDay,
    this.bankAccount,
    this.address,
    required this.success,
    this.errorMessage,
  });
}

// ── 인터페이스 ────────────────────────────────────────────────────────────────

abstract class ContractScanner {
  /// 이미지 파일 경로를 받아 OCR 결과를 반환합니다.
  Future<ScanResult> scanFromFile(String imagePath);

  /// 카메라로 바로 찍어 스캔합니다.
  Future<ScanResult> scanFromCamera();
}

// ── Stub 구현 (더미 계약 정보 반환) ──────────────────────────────────────────

class ContractScannerStub implements ContractScanner {
  @override
  Future<ScanResult> scanFromFile(String imagePath) async {
    // TODO: google_mlkit_text_recognition 활성화 후 실제 OCR 구현
    await Future.delayed(const Duration(seconds: 1)); // 스캔 시뮬레이션
    return _dummyResult();
  }

  @override
  Future<ScanResult> scanFromCamera() async {
    // TODO: image_picker로 카메라 열고 ML Kit으로 인식
    await Future.delayed(const Duration(seconds: 1));
    return _dummyResult();
  }

  ScanResult _dummyResult() => const ScanResult(
        success: true,
        monthlyRentWon: 550000,
        paymentDueDay: 5,
        bankAccount: '국민은행 123-456-789012',
        address: '서울시 마포구 와우산로 94',
      );
}

// ContractCard에 스캔 결과를 적용하는 확장 메서드
extension ScanResultApply on ContractCard {
  ContractCard applyResult(ScanResult result) => copyWith(
        monthlyRentWon: result.monthlyRentWon,
        paymentDueDay: result.paymentDueDay,
        bankAccount: result.bankAccount,
        address: result.address,
      );
}
