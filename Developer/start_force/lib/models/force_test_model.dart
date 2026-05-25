class ForceTestModel {
  final String id;
  final String swimmerId;
  final String swimmerName;
  final double totalPeakKgf;
  final double frontPeakKgf;
  final double backPeakKgf;
  final double rfdKgfPerSecond;
  final double balanceFrontPercent;
  final double balanceBackPercent;

  const ForceTestModel({
    required this.id,
    required this.swimmerId,
    required this.swimmerName,
    required this.totalPeakKgf,
    required this.frontPeakKgf,
    required this.backPeakKgf,
    required this.rfdKgfPerSecond,
    required this.balanceFrontPercent,
    required this.balanceBackPercent,
  });

  static double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory ForceTestModel.fromMap(String id, Map<String, dynamic> data) {
    return ForceTestModel(
      id: id,
      swimmerId: data['swimmerId']?.toString() ?? '',
      swimmerName: data['swimmerName']?.toString() ?? 'Unknown Swimmer',
      totalPeakKgf: number(data['totalPeakKgf']),
      frontPeakKgf: number(data['frontPeakKgf']),
      backPeakKgf: number(data['backPeakKgf']),
      rfdKgfPerSecond: number(data['rfdKgfPerSecond']),
      balanceFrontPercent: number(data['balanceFrontPercent']),
      balanceBackPercent: number(data['balanceBackPercent']),
    );
  }
}
