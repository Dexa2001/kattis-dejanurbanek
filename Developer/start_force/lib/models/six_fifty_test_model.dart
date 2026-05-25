class SixFiftyRowModel {
  final String swimmerId;
  final String swimmerName;

  final double split1;
  final double split2;
  final double split3;
  final double split4;
  final double split5;
  final double split6;

  final String lactate;
  final String predictionRange;

  const SixFiftyRowModel({
    required this.swimmerId,
    required this.swimmerName,
    required this.split1,
    required this.split2,
    required this.split3,
    required this.split4,
    required this.split5,
    required this.split6,
    required this.lactate,
    required this.predictionRange,
  });

  static double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory SixFiftyRowModel.fromMap(Map<String, dynamic> data) {
    return SixFiftyRowModel(
      swimmerId: data['swimmerId']?.toString() ?? '',
      swimmerName: data['swimmerName']?.toString() ?? '',

      split1: number(data['split1']),
      split2: number(data['split2']),
      split3: number(data['split3']),
      split4: number(data['split4']),
      split5: number(data['split5']),
      split6: number(data['split6']),

      lactate: data['lactate']?.toString() ?? '/',
      predictionRange: data['predictionRange']?.toString() ?? 'No prediction',
    );
  }
}

class SixFiftyTestModel {
  final String id;

  final String groupName;
  final String course;
  final String testDate;

  final List<SixFiftyRowModel> rows;

  const SixFiftyTestModel({
    required this.id,
    required this.groupName,
    required this.course,
    required this.testDate,
    required this.rows,
  });

  factory SixFiftyTestModel.fromMap(String id, Map<String, dynamic> data) {
    final rawRows = data['rows'] as List<dynamic>? ?? [];

    return SixFiftyTestModel(
      id: id,
      groupName: data['groupName']?.toString() ?? '',
      course: data['course']?.toString() ?? '',
      testDate: data['testDate']?.toString() ?? '',
      rows:
          rawRows
              .whereType<Map>()
              .map(
                (row) =>
                    SixFiftyRowModel.fromMap(Map<String, dynamic>.from(row)),
              )
              .toList(),
    );
  }
}
