import 'dart:async';
import '../bluetooth/bluetooth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'test_detail_screen.dart';
import '../services/pdf_report_service.dart';

class ForceSample {
  final double time;
  final double front;
  final double back;

  const ForceSample({
    required this.time,
    required this.front,
    required this.back,
  });

  double get total => front + back;

  Map<String, dynamic> toMap() {
    return {'time': time, 'front': front, 'back': back, 'total': total};
  }
}

class RunTestScreen extends StatefulWidget {
  const RunTestScreen({super.key});

  @override
  State<RunTestScreen> createState() => _RunTestScreenState();
}

class _RunTestScreenState extends State<RunTestScreen>
    with SingleTickerProviderStateMixin {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final BluetoothService bluetoothService = BluetoothService();

  StreamSubscription<ForceSensorReading>? readingSubscription;

  String? selectedSwimmerId;
  Map<String, dynamic>? selectedSwimmer;

  bool deviceConnected = false;
  bool isTesting = false;
  bool isSaving = false;

  double frontForce = 0;
  double backForce = 0;
  double peakFront = 0;
  double peakBack = 0;
  double peakTotal = 0;
  double time = 0;

  DateTime now = DateTime.now();
  DateTime? testStartedAt;

  Timer? sensorTimer;
  Timer? clockTimer;

  List<ForceSample> samples = [];

  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 1.0,
    )..repeat(reverse: true);

    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    sensorTimer?.cancel();
    clockTimer?.cancel();
    pulseController.dispose();
    readingSubscription?.cancel();
    super.dispose();
  }

  String formatClock(DateTime dateTime) =>
      DateFormat('h:mm:ss a').format(dateTime);

  String formatDate(DateTime dateTime) =>
      DateFormat('MMMM d, yyyy').format(dateTime);

  double avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get averageFront => avg(samples.map((s) => s.front).toList());
  double get averageBack => avg(samples.map((s) => s.back).toList());
  double get averageTotal => avg(samples.map((s) => s.total).toList());

  double get swimmerWeightLbs {
    final value = selectedSwimmer?['weightLbs'];
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get swimmerWeightKgf => swimmerWeightLbs * 0.453592;

  double weightPercent(double forceKgf) {
    if (swimmerWeightKgf <= 0) return 0;
    return (forceKgf / swimmerWeightKgf) * 100;
  }

  String get coachingNote {
    if (averageTotal == 0) return 'Run a test to generate coaching feedback.';

    final frontShare = averageFront / averageTotal * 100;
    final backShare = averageBack / averageTotal * 100;
    final diff = (frontShare - backShare).abs();

    if (diff < 8) {
      return 'Balanced start. Keep building total force and consistency.';
    }

    if (frontShare > backShare) {
      return 'Front-foot dominant. Monitor back-leg drive and rear-foot pressure.';
    }

    return 'Back-foot dominant. Monitor front-foot stability and pressure application.';
  }

  Future<void> startTest() async {
    if (selectedSwimmerId == null || selectedSwimmer == null) {
      showMessage('Select a swimmer first.');
      return;
    }

    if (!bluetoothService.isConnected && !deviceConnected) {
      showMessage('No sensor connected.');
      return;
    }

    sensorTimer?.cancel();
    await readingSubscription?.cancel();

    setState(() {
      isTesting = true;
      testStartedAt = DateTime.now();

      frontForce = 0;
      backForce = 0;

      peakFront = 0;
      peakBack = 0;
      peakTotal = 0;

      time = 0;
      samples.clear();
    });

    try {
      await bluetoothService.startStreaming();
    } catch (_) {}

    readingSubscription = bluetoothService.readings.listen((reading) {
      if (!mounted || !isTesting) return;

      final total = reading.totalKgf;

      setState(() {
        frontForce = reading.frontKgf;
        backForce = reading.backKgf;

        if (frontForce > peakFront) peakFront = frontForce;
        if (backForce > peakBack) peakBack = backForce;
        if (total > peakTotal) peakTotal = total;

        time = reading.timestampMs / 1000;

        samples.add(
          ForceSample(time: time, front: frontForce, back: backForce),
        );
      });

      if (time >= 15.0) {
        finishTest();
      }
    });

    // FALLBACK MOCK MODE
    if (!bluetoothService.isConnected) {
      sensorTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        final fakeFront = 40 + (time * 3.2);
        final fakeBack = 60 + (time * 4.1);

        final total = fakeFront + fakeBack;

        if (!mounted) return;

        setState(() {
          frontForce = fakeFront;
          backForce = fakeBack;

          if (frontForce > peakFront) peakFront = frontForce;
          if (backForce > peakBack) peakBack = backForce;
          if (total > peakTotal) peakTotal = total;

          samples.add(
            ForceSample(time: time, front: frontForce, back: backForce),
          );

          time += 0.12;
        });

        if (time >= 15.0) {
          finishTest();
        }
      });
    }
  }

  Future<void> finishTest() async {
    if (!isTesting) return;

    sensorTimer?.cancel();
    await readingSubscription?.cancel();

    try {
      await bluetoothService.stopStreaming();
    } catch (_) {}

    setState(() => isTesting = false);

    if (samples.isEmpty) return;

    final saved = await saveTest();

    if (!mounted || saved == null) return;

    showFinishedDialog(testId: saved['testId'], testData: saved['testData']);
  }

  Future<Map<String, dynamic>?> saveTest() async {
    if (uid == null || selectedSwimmerId == null || selectedSwimmer == null) {
      return null;
    }

    setState(() => isSaving = true);

    final frontShare =
        averageTotal == 0 ? 0 : averageFront / averageTotal * 100;
    final backShare = averageTotal == 0 ? 0 : averageBack / averageTotal * 100;

    final testData = {
      'swimmerId': selectedSwimmerId,
      'swimmerName':
          '${selectedSwimmer!['firstName']} ${selectedSwimmer!['lastName']}',
      'createdAt': FieldValue.serverTimestamp(),
      'testStartedAt': testStartedAt?.toIso8601String(),
      'durationSeconds': time,
      'frontAverageKgf': averageFront,
      'frontPeakKgf': peakFront,
      'frontBodyWeightPercentAverage': weightPercent(averageFront),
      'frontBodyWeightPercentPeak': weightPercent(peakFront),
      'backAverageKgf': averageBack,
      'backPeakKgf': peakBack,
      'backBodyWeightPercentAverage': weightPercent(averageBack),
      'backBodyWeightPercentPeak': weightPercent(peakBack),
      'totalAverageKgf': averageTotal,
      'totalPeakKgf': peakTotal,
      'balanceFrontPercent': frontShare,
      'balanceBackPercent': backShare,
      'weightDistribution':
          '${frontShare.toStringAsFixed(0)} / ${backShare.toStringAsFixed(0)}',
      'rfdKgfPerSecond': time == 0 ? 0 : peakTotal / time,
      'coachingNote': coachingNote,
      'samples': samples.map((s) => s.toMap()).toList(),
    };

    try {
      final swimmerTestRef = await FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('swimmers')
          .doc(selectedSwimmerId)
          .collection('tests')
          .add(testData);

      await FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('tests')
          .doc(swimmerTestRef.id)
          .set({...testData, 'testId': swimmerTestRef.id});

      return {
        'testId': swimmerTestRef.id,
        'testData': {...testData, 'testId': swimmerTestRef.id},
      };
    } catch (e) {
      showMessage('Could not save test: $e');
      return null;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showFinishedDialog({
    required String testId,
    required Map<String, dynamic> testData,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF061226),
            title: const Text('Test Saved'),
            content: const Text(
              'The test was saved successfully. You can view details or create a PDF report now.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  PdfReportService.printReport(
                    testData: testData,
                    swimmerData: selectedSwimmer,
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Print PDF'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TestDetailScreen(
                            testData: testData,
                            swimmerData: selectedSwimmer,
                            testId: testId,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Details'),
              ),
            ],
          ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<FlSpot> spotsFor(String type) {
    if (samples.isEmpty) return [const FlSpot(0, 0)];

    return samples.map((s) {
      if (type == 'front') return FlSpot(s.time, s.front);
      if (type == 'back') return FlSpot(s.time, s.back);
      return FlSpot(s.time, s.total);
    }).toList();
  }

  Widget statusCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111C2E),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            FadeTransition(
              opacity: pulseController,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 14),
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCard(String title, String value, Color color, {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white54)),
          ],
        ],
      ),
    );
  }

  Widget swimmerDropdown() {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('coaches')
              .doc(uid)
              .collection('swimmers')
              .orderBy('lastNameLower')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final swimmers = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2E),
            borderRadius: BorderRadius.circular(18),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSwimmerId ?? 'none',
              isExpanded: true,
              dropdownColor: const Color(0xFF111C2E),
              items: [
                const DropdownMenuItem(
                  value: 'none',
                  child: Text('Select Swimmer'),
                ),
                ...swimmers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('${data['firstName']} ${data['lastName']}'),
                  );
                }),
              ],
              onChanged:
                  isTesting
                      ? null
                      : (value) {
                        if (value == null || value == 'none') {
                          setState(() {
                            selectedSwimmerId = null;
                            selectedSwimmer = null;
                          });
                          return;
                        }

                        final doc = swimmers.firstWhere((d) => d.id == value);
                        setState(() {
                          selectedSwimmerId = value;
                          selectedSwimmer = doc.data() as Map<String, dynamic>;
                        });
                      },
            ),
          ),
        );
      },
    );
  }

  Widget mainChart() {
    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(18, 18, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          minY: 0,
          maxY: 320,
          minX: time <= 4.8 ? 0 : time - 4.8,
          maxX: time <= 4.8 ? 4.8 : time,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                reservedSize: 36,
                interval: 1,
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
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsFor('back'),
              isCurved: true,
              color: const Color(0xFF00B8A9),
              barWidth: 4,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsFor('total'),
              isCurved: true,
              color: Colors.orange,
              barWidth: 4,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalForce = frontForce + backForce;
    final frontBalance = totalForce == 0 ? 0 : frontForce / totalForce * 100;
    final backBalance = totalForce == 0 ? 0 : backForce / totalForce * 100;
    final rfd = time == 0 ? 0 : peakTotal / time;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Run Test',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select swimmer, run test, save force data',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              swimmerDropdown(),
              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        statusCard(
                          title:
                              deviceConnected
                                  ? 'Device Connected'
                                  : 'Device Not Connected',
                          subtitle:
                              deviceConnected
                                  ? 'Ready to receive sensor data'
                                  : 'Tap here to mock-connect for testing',
                          color:
                              deviceConnected
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                          icon: Icons.sensors,
                          onTap:
                              isTesting
                                  ? null
                                  : () => setState(
                                    () => deviceConnected = !deviceConnected,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        statusCard(
                          title: isTesting ? 'Test Running' : 'Test Idle',
                          subtitle:
                              isTesting
                                  ? 'Collecting samples, max 15 seconds'
                                  : 'Press start when ready',
                          color:
                              isTesting
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                          icon: Icons.timer,
                          onTap: null,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: statusCard(
                          title:
                              deviceConnected
                                  ? 'Device Connected'
                                  : 'Device Not Connected',
                          subtitle:
                              deviceConnected
                                  ? 'Ready to receive sensor data'
                                  : 'Tap here to mock-connect for testing',
                          color:
                              deviceConnected
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                          icon: Icons.sensors,
                          onTap:
                              isTesting
                                  ? null
                                  : () => setState(
                                    () => deviceConnected = !deviceConnected,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: statusCard(
                          title: isTesting ? 'Test Running' : 'Test Idle',
                          subtitle:
                              isTesting
                                  ? 'Collecting samples, max 15 seconds'
                                  : 'Press start when ready',
                          color:
                              isTesting
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                          icon: Icons.timer,
                          onTap: null,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        statCard(
                          'Live Total Force',
                          '${totalForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF111C2E),
                          subtitle: 'Front + Back',
                        ),
                        const SizedBox(height: 16),
                        statCard(
                          'Front Foot',
                          '${frontForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF1976FF),
                          subtitle: 'Peak ${peakFront.toStringAsFixed(1)} kgf',
                        ),
                        const SizedBox(height: 16),
                        statCard(
                          'Back Foot',
                          '${backForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF00B8A9),
                          subtitle: 'Peak ${peakBack.toStringAsFixed(1)} kgf',
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: statCard(
                          'Live Total Force',
                          '${totalForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF111C2E),
                          subtitle: 'Front + Back',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: statCard(
                          'Front Foot',
                          '${frontForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF1976FF),
                          subtitle: 'Peak ${peakFront.toStringAsFixed(1)} kgf',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: statCard(
                          'Back Foot',
                          '${backForce.toStringAsFixed(1)} kgf',
                          const Color(0xFF00B8A9),
                          subtitle: 'Peak ${peakBack.toStringAsFixed(1)} kgf',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              mainChart(),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        statCard(
                          'Peak Total',
                          '${peakTotal.toStringAsFixed(1)} kgf',
                          const Color(0xFF111C2E),
                        ),
                        const SizedBox(height: 16),
                        statCard(
                          'Balance',
                          '${frontBalance.toStringAsFixed(0)}% / ${backBalance.toStringAsFixed(0)}%',
                          const Color(0xFF111C2E),
                          subtitle: 'Front / Back',
                        ),
                        const SizedBox(height: 16),
                        statCard(
                          'RFD',
                          '${rfd.toStringAsFixed(1)} kgf/s',
                          const Color(0xFF111C2E),
                          subtitle: 'Peak total / time',
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: statCard(
                          'Peak Total',
                          '${peakTotal.toStringAsFixed(1)} kgf',
                          const Color(0xFF111C2E),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: statCard(
                          'Balance',
                          '${frontBalance.toStringAsFixed(0)}% / ${backBalance.toStringAsFixed(0)}%',
                          const Color(0xFF111C2E),
                          subtitle: 'Front / Back',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: statCard(
                          'RFD',
                          '${rfd.toStringAsFixed(1)} kgf/s',
                          const Color(0xFF111C2E),
                          subtitle: 'Peak total / time',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : () {
                            if (isTesting) {
                              finishTest();
                            } else {
                              startTest();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isTesting ? Colors.red : const Color(0xFF1976FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    isSaving
                        ? 'SAVING...'
                        : isTesting
                        ? 'STOP + SAVE'
                        : 'START TEST',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
