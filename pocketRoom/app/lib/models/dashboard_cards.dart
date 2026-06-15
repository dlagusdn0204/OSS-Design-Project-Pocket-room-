
import 'contract_card.dart';
import 'electricity_card.dart';
import 'city_gas_card.dart';

class DashboardCards {
  final ContractCard contract;
  final ElectricityCard electricity;
  final CityGasCard cityGas;

  const DashboardCards({
    required this.contract,
    required this.electricity,
    required this.cityGas,
  });
}
