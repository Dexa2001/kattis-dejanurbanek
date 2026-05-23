import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String text(dynamic value) {
    return value?.toString() ?? '';
  }

  static List<Map<String, dynamic>> samplesFrom(Map<String, dynamic> testData) {
    final raw = testData['samples'];

    if (raw is List) {
      return raw.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    }

    return [];
  }

  static String formatDate(dynamic value) {
    try {
      if (value == null) return DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());

      if (value.toString().contains('Timestamp')) {
        return value.toString();
      }

      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return DateFormat('MMM d, yyyy h:mm a').format(parsed);
      }

      return value.toString();
    } catch (_) {
      return DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
    }
  }

  static Future<void> printReport({
    required Map<String, dynamic> testData,
    Map<String, dynamic>? swimmerData,
  }) async {
    final bytes = await generateReport(
      testData: testData,
      swimmerData: swimmerData,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'swimforce_start_test_report.pdf',
    );
  }

  static Future<void> shareReport({
    required Map<String, dynamic> testData,
    Map<String, dynamic>? swimmerData,
  }) async {
    final bytes = await generateReport(
      testData: testData,
      swimmerData: swimmerData,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'swimforce_start_test_report.pdf',
    );
  }

  static Future<Uint8List> generateReport({
    required Map<String, dynamic> testData,
    Map<String, dynamic>? swimmerData,
  }) async {
    final pdf = pw.Document();

    final samples = samplesFrom(testData);

    final swimmerName = text(testData['swimmerName']).isNotEmpty
        ? text(testData['swimmerName'])
        : '${text(swimmerData?['firstName'])} ${text(swimmerData?['lastName'])}';

    final frontAverage = number(testData['frontAverageKgf']);
    final backAverage = number(testData['backAverageKgf']);
    final totalAverage = number(testData['totalAverageKgf']);

    final frontPeak = number(testData['frontPeakKgf']);
    final backPeak = number(testData['backPeakKgf']);
    final totalPeak = number(testData['totalPeakKgf']);

    final frontBalance = number(testData['balanceFrontPercent']);
    final backBalance = number(testData['balanceBackPercent']);

    final rfd = number(testData['rfdKgfPerSecond']);
    final duration = number(testData['durationSeconds']);

    final frontBwAvg = number(testData['frontBodyWeightPercentAverage']);
    final backBwAvg = number(testData['backBodyWeightPercentAverage']);
    final frontBwPeak = number(testData['frontBodyWeightPercentPeak']);
    final backBwPeak = number(testData['backBodyWeightPercentPeak']);

    final coachingNote = text(testData['coachingNote']);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            header(swimmerName, testData),
            pw.SizedBox(height: 18),

            sectionTitle('Performance Summary'),
            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                metricCard('Front Peak', '${frontPeak.toStringAsFixed(1)} kgf', 'Avg ${frontAverage.toStringAsFixed(1)}'),
                pw.SizedBox(width: 8),
                metricCard('Back Peak', '${backPeak.toStringAsFixed(1)} kgf', 'Avg ${backAverage.toStringAsFixed(1)}'),
                pw.SizedBox(width: 8),
                metricCard('Total Peak', '${totalPeak.toStringAsFixed(1)} kgf', 'Avg ${totalAverage.toStringAsFixed(1)}'),
              ],
            ),

            pw.SizedBox(height: 12),

            pw.Row(
              children: [
                metricCard('Balance', '${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)}', 'Front / Back'),
                pw.SizedBox(width: 8),
                metricCard('RFD', '${rfd.toStringAsFixed(1)} kgf/s', 'Peak total / time'),
                pw.SizedBox(width: 8),
                metricCard('Duration', '${duration.toStringAsFixed(2)} s', 'Test length'),
              ],
            ),

            pw.SizedBox(height: 22),

            sectionTitle('Body Weight Loading'),
            pw.SizedBox(height: 8),

            infoBox(
              'Formula',
              '% body weight = force in kgf / swimmer body weight in kg x 100',
            ),

            pw.SizedBox(height: 10),

            pw.Row(
              children: [
                metricCard('Front Avg BW', '${frontBwAvg.toStringAsFixed(0)}%', 'Peak ${frontBwPeak.toStringAsFixed(0)}%'),
                pw.SizedBox(width: 8),
                metricCard('Back Avg BW', '${backBwAvg.toStringAsFixed(0)}%', 'Peak ${backBwPeak.toStringAsFixed(0)}%'),
                pw.SizedBox(width: 8),
                metricCard('Distribution', '${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)}', 'Front / Back'),
              ],
            ),

            pw.SizedBox(height: 22),

            sectionTitle('Force Profile Chart'),
            pw.SizedBox(height: 8),
            forceChart(samples),

            pw.SizedBox(height: 22),

            sectionTitle('Coach Analysis'),
            pw.SizedBox(height: 8),
            infoBox('Recommendation', coachingNote),

            pw.SizedBox(height: 22),

            sectionTitle('Detailed Metrics'),
            pw.SizedBox(height: 8),
            metricsTable(testData),

            pw.SizedBox(height: 22),

            sectionTitle('Sample Data Preview'),
            pw.SizedBox(height: 8),
            sampleTable(samples),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget header(String swimmerName, Map<String, dynamic> testData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#061226'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SWIMFORCE +',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Start Force Test Report',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                swimmerName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                formatDate(testData['testStartedAt']),
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#061226'),
      ),
    );
  }

  static pw.Widget metricCard(String title, String value, String subtitle) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#EEF4FF'),
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColor.fromHex('#D7E4FF')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget infoBox(String title, String body) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7F9FC'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#E3E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(body, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget forceChart(List<Map<String, dynamic>> samples) {
    if (samples.isEmpty) {
      return infoBox('Chart unavailable', 'No sample data was recorded.');
    }

    final limited = samples.length > 80 ? samples.sublist(samples.length - 80) : samples;

    final maxTotal = limited
        .map((s) => number(s['total']))
        .fold<double>(0, (a, b) => b > a ? b : a);

    final scaleMax = maxTotal <= 0 ? 300 : maxTotal;

    return pw.Container(
      height: 180,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7F9FC'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#E3E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              legend('#1976FF', 'Front'),
              pw.SizedBox(width: 14),
              legend('#00B8A9', 'Back'),
              pw.SizedBox(width: 14),
              legend('#FF9800', 'Total'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: limited.map((sample) {
                final total = number(sample['total']);
                final height = (total / scaleMax) * 120;

                return pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                    child: pw.Container(
                      height: height,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FF9800'),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Chart displays total force trend across recorded samples.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget legend(String color, String label) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex(color),
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget metricsTable(Map<String, dynamic> testData) {
    final rows = [
      ['Front Average', '${number(testData['frontAverageKgf']).toStringAsFixed(2)} kgf'],
      ['Front Peak', '${number(testData['frontPeakKgf']).toStringAsFixed(2)} kgf'],
      ['Back Average', '${number(testData['backAverageKgf']).toStringAsFixed(2)} kgf'],
      ['Back Peak', '${number(testData['backPeakKgf']).toStringAsFixed(2)} kgf'],
      ['Total Average', '${number(testData['totalAverageKgf']).toStringAsFixed(2)} kgf'],
      ['Total Peak', '${number(testData['totalPeakKgf']).toStringAsFixed(2)} kgf'],
      ['Balance Front', '${number(testData['balanceFrontPercent']).toStringAsFixed(1)}%'],
      ['Balance Back', '${number(testData['balanceBackPercent']).toStringAsFixed(1)}%'],
      ['RFD', '${number(testData['rfdKgfPerSecond']).toStringAsFixed(2)} kgf/s'],
      ['Duration', '${number(testData['durationSeconds']).toStringAsFixed(2)} s'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E3E8F0')),
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            tableCell(row[0], bold: true),
            tableCell(row[1]),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget sampleTable(List<Map<String, dynamic>> samples) {
    final preview = samples.take(12).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E3E8F0')),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEF4FF')),
          children: [
            tableCell('Time', bold: true),
            tableCell('Front', bold: true),
            tableCell('Back', bold: true),
            tableCell('Total', bold: true),
          ],
        ),
        ...preview.map((sample) {
          return pw.TableRow(
            children: [
              tableCell('${number(sample['time']).toStringAsFixed(2)} s'),
              tableCell('${number(sample['front']).toStringAsFixed(1)}'),
              tableCell('${number(sample['back']).toStringAsFixed(1)}'),
              tableCell('${number(sample['total']).toStringAsFixed(1)}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}