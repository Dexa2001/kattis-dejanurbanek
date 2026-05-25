import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/pdf_report_service.dart';

class TestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> testData;
  final Map<String, dynamic>? swimmerData;
  final String? testId;

  const TestDetailScreen({
    super.key,
    required this.testData,
    this.swimmerData,
    this.testId,
  });

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  int selectedIndex = 0;
  bool isPrinting = false;

  double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String text(dynamic value) => value?.toString() ?? '';

  List<Map<String, dynamic>> get samples {
    final raw = widget.testData['samples'];

    if (raw is List) {
      return raw.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    }

    return [];
  }

  String get swimmerName {
    final savedName = text(widget.testData['swimmerName']);
    if (savedName.isNotEmpty) return savedName;

    final first = text(widget.swimmerData?['firstName']);
    final last = text(widget.swimmerData?['lastName']);

    return '$first $last'.trim().isEmpty ? 'Swimmer' : '$first $last';
  }

  String formatDate() {
    final raw = widget.testData['testStartedAt'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');

    if (parsed == null) {
      return DateFormat('MMM d, yyyy h:mm a').format(DateTime.now());
    }

    return DateFormat('MMM d, yyyy h:mm a').format(parsed);
  }

  Future<void> printPdf() async {
    setState(() => isPrinting = true);

    try {
      await PdfReportService.printReport(
        testData: widget.testData,
        swimmerData: widget.swimmerData,
      );
    } finally {
      if (mounted) setState(() => isPrinting = false);
    }
  }

  Future<void> sharePdf() async {
    setState(() => isPrinting = true);

    try {
      await PdfReportService.shareReport(
        testData: widget.testData,
        swimmerData: widget.swimmerData,
      );
    } finally {
      if (mounted) setState(() => isPrinting = false);
    }
  }

  double weightPercent(double forceKgf) {
    final weightLbs = number(widget.swimmerData?['weightLbs']);
    final weightKgf = weightLbs * 0.453592;

    if (weightKgf <= 0) {
      return 0;
    }

    return forceKgf / weightKgf * 100;
  }

  List<FlSpot> spotsFor(String type) {
    if (samples.isEmpty) return [const FlSpot(0, 0)];

    return samples.map((sample) {
      final time = number(sample['time']);

      if (type == 'front') {
        return FlSpot(time, number(sample['front']));
      }

      if (type == 'back') {
        return FlSpot(time, number(sample['back']));
      }

      return FlSpot(time, number(sample['total']));
    }).toList();
  }

  Widget metricCard({
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget chart() {
    final selectedSample = samples.isEmpty ? null : samples[selectedIndex];
    final selectedTime = number(selectedSample?['time']);
    final maxX = samples.isEmpty ? 15.0 : number(samples.last['time']);

    return Container(
      height: 360,
      padding: const EdgeInsets.fromLTRB(18, 18, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          minY: 0,
          maxY: 320,
          minX: 0,
          maxX: maxX <= 0 ? 15 : maxX,
          gridData: const FlGridData(show: true, drawVerticalLine: true),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: selectedTime,
                color: Colors.white,
                strokeWidth: 2,
                dashArray: [8, 6],
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spotsFor('front'),
              isCurved: true,
              color: const Color(0xFF1976FF),
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                checkToShowDot:
                    (spot, barData) => (spot.x - selectedTime).abs() < 0.01,
              ),
            ),
            LineChartBarData(
              spots: spotsFor('back'),
              isCurved: true,
              color: const Color(0xFF00B8A9),
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                checkToShowDot:
                    (spot, barData) => (spot.x - selectedTime).abs() < 0.01,
              ),
            ),
            LineChartBarData(
              spots: spotsFor('total'),
              isCurved: true,
              color: Colors.orange,
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                checkToShowDot:
                    (spot, barData) => (spot.x - selectedTime).abs() < 0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summarySection() {
    final frontAvg = number(widget.testData['frontAverageKgf']);
    final frontPeak = number(widget.testData['frontPeakKgf']);
    final backAvg = number(widget.testData['backAverageKgf']);
    final backPeak = number(widget.testData['backPeakKgf']);
    final totalAvg = number(widget.testData['totalAverageKgf']);
    final totalPeak = number(widget.testData['totalPeakKgf']);
    final rfd = number(widget.testData['rfdKgfPerSecond']);
    final frontBalance = number(widget.testData['balanceFrontPercent']);
    final backBalance = number(widget.testData['balanceBackPercent']);

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        metricCard(
          title: 'Front Avg',
          value: '${frontAvg.toStringAsFixed(1)} kgf',
          color: const Color(0xFF1976FF),
          subtitle: 'Peak ${frontPeak.toStringAsFixed(1)} kgf',
        ),
        metricCard(
          title: 'Back Avg',
          value: '${backAvg.toStringAsFixed(1)} kgf',
          color: const Color(0xFF00B8A9),
          subtitle: 'Peak ${backPeak.toStringAsFixed(1)} kgf',
        ),
        metricCard(
          title: 'Total Avg',
          value: '${totalAvg.toStringAsFixed(1)} kgf',
          color: const Color(0xFF111C2E),
          subtitle: 'Peak ${totalPeak.toStringAsFixed(1)} kgf',
        ),
        metricCard(
          title: 'Balance',
          value:
              '${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)}',
          color: const Color(0xFF111C2E),
          subtitle: 'Front / Back',
        ),
        metricCard(
          title: 'RFD',
          value: rfd.toStringAsFixed(1),
          color: const Color(0xFF111C2E),
          subtitle: 'kgf/s',
        ),
      ],
    );
  }

  Widget sampleSlider() {
    if (samples.isEmpty) {
      return const Text('No sample data available.');
    }

    final sample = samples[selectedIndex];
    final front = number(sample['front']);
    final back = number(sample['back']);
    final total = number(sample['total']);
    final time = number(sample['time']);

    final frontBalance = total == 0 ? 0 : front / total * 100;
    final backBalance = total == 0 ? 0 : back / total * 100;

    return Column(
      children: [
        Slider(
          value: selectedIndex.toDouble(),
          min: 0,
          max: (samples.length - 1).toDouble(),
          divisions: samples.length > 1 ? samples.length - 1 : 1,
          label: '${time.toStringAsFixed(2)}s',
          onChanged: (value) {
            setState(() {
              selectedIndex = value.round();
            });
          },
        ),
        Text(
          'Viewing sample at ${time.toStringAsFixed(2)} seconds',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            metricCard(
              title: 'Front',
              value: '${front.toStringAsFixed(1)} kgf',
              color: const Color(0xFF1976FF),
              subtitle: '${weightPercent(front).toStringAsFixed(0)}% BW',
            ),
            metricCard(
              title: 'Back',
              value: '${back.toStringAsFixed(1)} kgf',
              color: const Color(0xFF00B8A9),
              subtitle: '${weightPercent(back).toStringAsFixed(0)}% BW',
            ),
            metricCard(
              title: 'Total',
              value: '${total.toStringAsFixed(1)} kgf',
              color: const Color(0xFF111C2E),
              subtitle: 'Instant force',
            ),
            metricCard(
              title: 'Balance',
              value:
                  '${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)}',
              color: const Color(0xFF111C2E),
              subtitle: 'Front / Back',
            ),
          ],
        ),
      ],
    );
  }

  Widget coachingBox() {
    final note = text(widget.testData['coachingNote']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_alt,
            color: Colors.orangeAccent,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              note.isEmpty ? 'No coaching note available.' : note,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = number(widget.testData['durationSeconds']);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Details',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$swimmerName • ${formatDate()} • ${duration.toStringAsFixed(2)}s',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isPrinting ? null : printPdf,
                    icon: const Icon(Icons.print),
                    label: const Text('Print PDF'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isPrinting ? null : sharePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Share PDF'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              chart(),
              const SizedBox(height: 18),
              sampleSlider(),
              const SizedBox(height: 26),

              const Text(
                'Test Summary',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              summarySection(),

              const SizedBox(height: 26),

              const Text(
                'Coach Analysis',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              coachingBox(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
