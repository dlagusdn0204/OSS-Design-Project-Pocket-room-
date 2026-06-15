
import '../models/contract_card.dart';


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


abstract class ContractScanner {
  Future<ScanResult> scanFromFile(String imagePath);

  Future<ScanResult> scanFromCamera();
}


class ContractScannerStub implements ContractScanner {
  @override
  Future<ScanResult> scanFromFile(String imagePath) async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyResult();
  }

  @override
  Future<ScanResult> scanFromCamera() async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyResult();
  }

  ScanResult _dummyResult() => const ScanResult(
        success: true,
        monthlyRentWon: 550000,
        paymentDueDay: 5,
        bankAccount: '국민은행 123-456-789012',
        address: '경북 경산시 대동 214-1',
      );
}

extension ScanResultApply on ContractCard {
  ContractCard applyResult(ScanResult result) => copyWith(
        monthlyRentWon: result.monthlyRentWon,
        paymentDueDay: result.paymentDueDay,
        bankAccount: result.bankAccount,
        address: result.address,
      );
}
