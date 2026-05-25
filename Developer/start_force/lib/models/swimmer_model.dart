class SwimmerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String dob;
  final int weightLbs;
  final String heightDisplay;
  final String frontFoot;
  final String backFoot;

  const SwimmerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.weightLbs,
    required this.heightDisplay,
    required this.frontFoot,
    required this.backFoot,
  });

  String get fullName => '$firstName $lastName';

  factory SwimmerModel.fromMap(String id, Map<String, dynamic> data) {
    return SwimmerModel(
      id: id,
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      dob: data['dob']?.toString() ?? '',
      weightLbs: int.tryParse(data['weightLbs']?.toString() ?? '') ?? 0,
      heightDisplay: data['heightDisplay']?.toString() ?? '',
      frontFoot: data['frontFoot']?.toString() ?? '',
      backFoot: data['backFoot']?.toString() ?? '',
    );
  }
}
