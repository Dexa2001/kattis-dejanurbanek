import 'package:flutter/material.dart';

import '../services/six_fifty_pdf_service.dart';

class SixFiftyTestDetailScreen extends StatelessWidget {
  final String testId;
  final Map<String, dynamic> testData;

  const SixFiftyTestDetailScreen({
    super.key,
    required this.testId,
    required this.testData,
  });

  String split(dynamic value) {
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return '/';
    return parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final rows = testData['rows'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF02112B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF02112B),
        title: const Text('6×50 Test Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              SixFiftyPdfService.printReport(testData: testData);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFE8C7C7)),
              headingTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Stroke')),
                DataColumn(label: Text('Interval')),
                DataColumn(label: Text('1st')),
                DataColumn(label: Text('2nd')),
                DataColumn(label: Text('3rd')),
                DataColumn(label: Text('4th')),
                DataColumn(label: Text('5th')),
                DataColumn(label: Text('6th')),
                DataColumn(label: Text('A Method')),
                DataColumn(label: Text('B Method')),
                DataColumn(label: Text('Range')),
                DataColumn(label: Text('LAC')),
                DataColumn(label: Text('Notes')),
              ],
              rows:
                  rows.map((item) {
                    final row = Map<String, dynamic>.from(item as Map);
                    final times = row['times'] as List<dynamic>? ?? [];

                    return DataRow(
                      cells: [
                        DataCell(Text(row['swimmerName']?.toString() ?? '')),
                        DataCell(Text(row['stroke']?.toString() ?? '')),
                        DataCell(Text(row['interval']?.toString() ?? '')),
                        ...List.generate(6, (i) {
                          return DataCell(
                            Text(i < times.length ? split(times[i]) : '/'),
                          );
                        }),
                        DataCell(
                          Text(row['predictionAText']?.toString() ?? '/'),
                        ),
                        DataCell(
                          Text(row['predictionBText']?.toString() ?? '/'),
                        ),
                        DataCell(
                          Text(row['predictionRange']?.toString() ?? '/'),
                        ),
                        DataCell(Text(row['lactate']?.toString() ?? '/')),
                        DataCell(Text(row['notes']?.toString() ?? '')),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
