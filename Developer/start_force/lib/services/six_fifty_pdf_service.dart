import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SixFiftyPdfService {
  static String raceTime(double seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds - (minutes * 60);
    return '$minutes:${remaining.toStringAsFixed(2).padLeft(5, '0')}';
  }

  static Future<void> printReport({
    required Map<String, dynamic> testData,
  }) async {
    final pdf = pw.Document();

    final rows =
        (testData['rows'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    final groupName = testData['groupName']?.toString() ?? '';
    final course = testData['course']?.toString() ?? '';
    final testDate = testData['testDate']?.toString() ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.fromLTRB(14, 16, 14, 16),
        build:
            (context) => [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8C7C7'),
                  border: pw.Border.all(width: 1.2),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '6x50 TEST SET',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      'GROUP: $groupName   COURSE: $course   DATE: $testDate',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(width: 0.45),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.7),
                  1: pw.FlexColumnWidth(0.65),
                  2: pw.FlexColumnWidth(0.75),
                  3: pw.FlexColumnWidth(0.68),
                  4: pw.FlexColumnWidth(0.68),
                  5: pw.FlexColumnWidth(0.68),
                  6: pw.FlexColumnWidth(0.68),
                  7: pw.FlexColumnWidth(0.68),
                  8: pw.FlexColumnWidth(0.68),
                  9: pw.FlexColumnWidth(0.65),
                  10: pw.FlexColumnWidth(1.75),
                  11: pw.FlexColumnWidth(1.35),
                },
                children: [_headerRow(), ...rows.map(_dataRow)],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '#1 from dive  |  #1-5 to turn  |  #6 to touch finish',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Prediction A = 1st + 6th + 2 x AVG(2-5)',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Prediction B = 1st + 6th + 2 x SLOWER AVG(2-5)',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Prediction Range = Method A to Method B',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.TableRow _headerRow() {
    final headers = [
      'Name',
      'Stroke',
      'Interval',
      '1st',
      '2nd',
      '3rd',
      '4th',
      '5th',
      '6th',
      'LAC',
      'Range',
      'Notes',
    ];

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEEEEE')),
      children:
          headers.map((text) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                text,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }).toList(),
    );
  }

  static pw.TableRow _dataRow(Map<String, dynamic> row) {
    final times =
        (row['times'] as List<dynamic>? ?? [])
            .map((e) => double.tryParse(e.toString()) ?? 0)
            .toList();

    final predictionA = double.tryParse(row['predictionA']?.toString() ?? '');
    final predictionB = double.tryParse(row['predictionB']?.toString() ?? '');

    final aText = predictionA == null ? '/' : raceTime(predictionA);
    final bText = predictionB == null ? '/' : raceTime(predictionB);
    final rangeText = row['predictionRange']?.toString() ?? '$aText - $bText';

    final cells = [
      row['swimmerName']?.toString() ?? '',
      row['stroke']?.toString() ?? '',
      row['interval']?.toString() ?? '',
      times.isNotEmpty ? times[0].toStringAsFixed(2) : '/',
      times.length > 1 ? times[1].toStringAsFixed(2) : '/',
      times.length > 2 ? times[2].toStringAsFixed(2) : '/',
      times.length > 3 ? times[3].toStringAsFixed(2) : '/',
      times.length > 4 ? times[4].toStringAsFixed(2) : '/',
      times.length > 5 ? times[5].toStringAsFixed(2) : '/',
      row['lactate']?.toString() ?? '/',
      rangeText,
      row['notes']?.toString() ?? '',
    ];

    return pw.TableRow(
      children: List.generate(cells.length, (index) {
        final isName = index == 0;
        final isRange = index == 10;

        return pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            cells[index],
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: isRange ? 8.5 : 8,
              fontWeight:
                  isName || isRange ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }
}
