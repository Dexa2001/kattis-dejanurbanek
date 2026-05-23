import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'test_detail_screen.dart';
import '../services/pdf_report_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  QueryDocumentSnapshot? findTestById(
  List<QueryDocumentSnapshot> tests,
  String? id,
) {
  if (id == null) return null;

  for (final test in tests) {
    if (test.id == id) return test;
  }

  return null;
}
  final uid = FirebaseAuth.instance.currentUser?.uid;

  String selectedMode = 'Team';
  String? selectedSwimmerId;
  Map<String, dynamic>? selectedSwimmer;

  String? compareAId;
  String? compareBId;

  double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String formatDate(Map<String, dynamic> test) {
    
    final raw = test['testStartedAt'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');

    if (parsed != null) {
      return DateFormat('MMM d, yyyy').format(parsed);
    }

    final createdAt = test['createdAt'];

    if (createdAt is Timestamp) {
      return DateFormat('MMM d, yyyy').format(createdAt.toDate());
    }

    return 'Unknown date';
  }
  String latestTestDate(List<QueryDocumentSnapshot> tests) {
  if (tests.isEmpty) return 'No tests yet';

  final data = tests.first.data() as Map<String, dynamic>;
  return 'Last test on ${formatDate(data)}';
}

  String formatShortDate(Map<String, dynamic> test) {
    final raw = test['testStartedAt'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');

    if (parsed != null) {
      return DateFormat('MMM d • h:mm a').format(parsed);
    }

    final createdAt = test['createdAt'];

    if (createdAt is Timestamp) {
      return DateFormat('MMM d • h:mm a').format(createdAt.toDate());
    }

    return 'Unknown date';
  }

  String zoneForPeak(double peak) {
    if (peak >= 300) return 'Elite';
    if (peak >= 240) return 'High';
    if (peak >= 180) return 'Developing';
    return 'Low';
  }

  Color zoneColor(String zone) {
    if (zone == 'Elite') return Colors.greenAccent;
    if (zone == 'High') return Colors.orangeAccent;
    if (zone == 'Developing') return const Color(0xFF1976FF);
    return Colors.redAccent;
  }

  double percentileRank({
    required double value,
    required List<double> allValues,
  }) {
    if (allValues.isEmpty) return 0;

    final belowOrEqual = allValues.where((v) => v <= value).length;

    return (belowOrEqual / allValues.length) * 100;
  }

  List<QueryDocumentSnapshot> filterTests(List<QueryDocumentSnapshot> allTests) {
    if (selectedMode == 'Swimmer' && selectedSwimmerId != null) {
      return allTests.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['swimmerId'] == selectedSwimmerId;
      }).toList();
    }

    return allTests;
  }

  List<QueryDocumentSnapshot> oldestToNewest(List<QueryDocumentSnapshot> docs) {
    return docs.reversed.toList();
  }

  double latestPeak(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return 0;
    final data = tests.first.data() as Map<String, dynamic>;
    return number(data['totalPeakKgf']);
  }

  double bestPeak(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return 0;

    return tests
        .map((doc) => number((doc.data() as Map<String, dynamic>)['totalPeakKgf']))
        .reduce((a, b) => a > b ? a : b);
  }

  double latestRfd(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return 0;
    final data = tests.first.data() as Map<String, dynamic>;
    return number(data['rfdKgfPerSecond']);
  }

  double latestAsymmetry(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return 0;

    final data = tests.first.data() as Map<String, dynamic>;

    final front = number(data['balanceFrontPercent']);
    final back = number(data['balanceBackPercent']);

    return (front - back).abs();
  }

  double readinessScore(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return 0;

    final avgPeak = average(
      tests
          .map((doc) => number((doc.data() as Map<String, dynamic>)['totalPeakKgf']))
          .toList(),
    );

    final avgRfd = average(
      tests
          .map((doc) => number((doc.data() as Map<String, dynamic>)['rfdKgfPerSecond']))
          .toList(),
    );

    final avgAsymmetry = average(
      tests.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final front = number(data['balanceFrontPercent']);
        final back = number(data['balanceBackPercent']);
        return (front - back).abs();
      }).toList(),
    );

    final power = (avgPeak / 3).clamp(0, 100).toDouble();
    final explosiveness = (avgRfd * 2).clamp(0, 100).toDouble();
    final symmetry = (100 - avgAsymmetry).clamp(0, 100).toDouble();

    return ((power * 0.35) + (explosiveness * 0.30) + (symmetry * 0.35))
        .clamp(0, 100)
        .toDouble();
  }

  String fatigueStatus(List<QueryDocumentSnapshot> tests) {
    if (tests.length < 3) {
      return 'Not enough data';
    }

    final latest = latestPeak(tests);

    final previous = tests.skip(1).take(3).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return number(data['totalPeakKgf']);
    }).toList();

    final previousAvg = average(previous);

    if (previousAvg == 0) return 'Not enough data';

    final change = ((latest - previousAvg) / previousAvg) * 100;

    if (change <= -10) return 'Fatigue risk';
    if (change <= -5) return 'Watch closely';
    if (change >= 8) return 'Improving';
    return 'Stable';
  }

  Color fatigueColor(String status) {
    if (status == 'Fatigue risk') return Colors.redAccent;
    if (status == 'Watch closely') return Colors.orangeAccent;
    if (status == 'Improving') return Colors.greenAccent;
    return Colors.white70;
  }

  void openTest(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestDetailScreen(
          testData: data,
          swimmerData: selectedSwimmer,
          testId: doc.id,
        ),
      ),
    );
  }

  Widget pageHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Progress',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget filtersBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        final modeBox = filterContainer(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMode,
              dropdownColor: const Color(0xFF111C2E),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'Team',
                  child: Text('Team Analytics'),
                ),
                DropdownMenuItem(
                  value: 'Swimmer',
                  child: Text('Individual Swimmer'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedMode = value;
                  compareAId = null;
                  compareBId = null;

                  if (value == 'Team') {
                    selectedSwimmerId = null;
                    selectedSwimmer = null;
                  }
                });
              },
            ),
          ),
        );

        final swimmerBox = selectedMode == 'Swimmer'
            ? StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('coaches')
                    .doc(uid)
                    .collection('swimmers')
                    .orderBy('lastNameLower')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return filterContainer(
                      child: const Text('Loading swimmers...'),
                    );
                  }

                  final swimmers = snapshot.data!.docs;

                  return filterContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSwimmerId ?? 'none',
                        dropdownColor: const Color(0xFF111C2E),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'none',
                            child: Text('Select Swimmer'),
                          ),
                          ...swimmers.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${data['firstName']} ${data['lastName']}',
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value == null || value == 'none') {
                            setState(() {
                              selectedSwimmerId = null;
                              selectedSwimmer = null;
                              compareAId = null;
                              compareBId = null;
                            });
                            return;
                          }

                          final doc = swimmers.firstWhere((d) => d.id == value);

                          setState(() {
                            selectedSwimmerId = value;
                            selectedSwimmer =
                                doc.data() as Map<String, dynamic>;
                            compareAId = null;
                            compareBId = null;
                          });
                        },
                      ),
                    ),
                  );
                },
              )
            : const SizedBox();

        if (compact) {
          return Column(
            children: [
              modeBox,
              if (selectedMode == 'Swimmer') ...[
                const SizedBox(height: 14),
                swimmerBox,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: modeBox),
            if (selectedMode == 'Swimmer') ...[
              const SizedBox(width: 14),
              Expanded(flex: 2, child: swimmerBox),
            ],
          ],
        );
      },
    );
  }

  Widget filterContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget overviewCards({
    required List<QueryDocumentSnapshot> tests,
    required List<QueryDocumentSnapshot> allTests,
  }) {
    if (tests.isEmpty) return const SizedBox();

    final latest = latestPeak(tests);
    final best = bestPeak(tests);
    final rfd = latestRfd(tests);
    final asymmetry = latestAsymmetry(tests);
    final readiness = readinessScore(tests);
    final fatigue = fatigueStatus(tests);
    final zone = zoneForPeak(latest);

    final allPeaks = allTests.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return number(data['totalPeakKgf']);
    }).toList();

    final percentile = percentileRank(
      value: latest,
      allValues: allPeaks,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
statCard(
  title: selectedMode == 'Team' ? 'Tests Logged' : 'Swimmer Tests',
  value: '${tests.length}',
  icon: Icons.assignment_turned_in,
  color: const Color(0xFF1976FF),
  subtitle: latestTestDate(tests),
),
          statCard(
            title: 'Latest Peak',
            value: '${latest.toStringAsFixed(1)} kgf',
            icon: Icons.bolt,
            color: Colors.orange,
            subtitle: 'Best ${best.toStringAsFixed(1)} kgf',
          ),
          statCard(
            title: 'Readiness',
            value: '${readiness.toStringAsFixed(0)} / 100',
            icon: Icons.speed,
            color: const Color(0xFF00B8A9),
            subtitle: 'RFD ${rfd.toStringAsFixed(1)} kgf/s',
          ),
          statCard(
            title: 'Percentile',
            value: '${percentile.toStringAsFixed(0)}%',
            icon: Icons.leaderboard,
            color: const Color(0xFF6C4DFF),
            subtitle: 'Compared to all saved tests',
          ),
          statCard(
            title: 'Asymmetry',
            value: '${asymmetry.toStringAsFixed(0)}%',
            icon: Icons.balance,
            color: asymmetry <= 8 ? Colors.greenAccent : Colors.orangeAccent,
            subtitle: 'Front/back difference',
          ),
          statCard(
            title: 'Fatigue',
            value: fatigue,
            icon: Icons.monitor_heart,
            color: fatigueColor(fatigue),
            subtitle: 'Based on recent peak trend',
          ),
          statCard(
            title: 'Force Zone',
            value: zone,
            icon: Icons.radar,
            color: zoneColor(zone),
            subtitle: 'Current total peak category',
          ),
        ];

        if (constraints.maxWidth < 900) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (constraints.maxWidth - 28) / 3,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget scoreCard({
    required String title,
    required double score,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0, 1),
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFF061226),
                  color: color,
                ),
              ),
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget scoringSection(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final peaks = tests.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return number(data['totalPeakKgf']);
    }).toList();

    final rfds = tests.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return number(data['rfdKgfPerSecond']);
    }).toList();

    final balanceDiffs = tests.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final front = number(data['balanceFrontPercent']);
      final back = number(data['balanceBackPercent']);
      return (front - back).abs();
    }).toList();

    final avgPeak = average(peaks);
    final avgRfd = average(rfds);
    final avgDiff = average(balanceDiffs);

    final powerScore = (avgPeak / 3).clamp(0, 100).toDouble();
    final explosivenessScore = (avgRfd * 2).clamp(0, 100).toDouble();
    final symmetryScore = (100 - avgDiff).clamp(0, 100).toDouble();
    final readiness = readinessScore(tests);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          scoreCard(
            title: 'Power',
            score: powerScore,
            color: Colors.orange,
            subtitle: 'Average peak force',
          ),
          scoreCard(
            title: 'Explosiveness',
            score: explosivenessScore,
            color: const Color(0xFF1976FF),
            subtitle: 'Rate of force development',
          ),
          scoreCard(
            title: 'Symmetry',
            score: symmetryScore,
            color: const Color(0xFF00B8A9),
            subtitle: 'Front/back balance',
          ),
          scoreCard(
            title: 'Readiness',
            score: readiness,
            color: const Color(0xFF6C4DFF),
            subtitle: 'Power, RFD, and symmetry',
          ),
        ];

        if (constraints.maxWidth < 950) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget trendChart(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final ordered = oldestToNewest(tests);

    final totalSpots = <FlSpot>[];
    final frontSpots = <FlSpot>[];
    final backSpots = <FlSpot>[];

    for (int i = 0; i < ordered.length; i++) {
      final data = ordered[i].data() as Map<String, dynamic>;
      final x = (i + 1).toDouble();

      totalSpots.add(FlSpot(x, number(data['totalPeakKgf'])));
      frontSpots.add(FlSpot(x, number(data['frontPeakKgf'])));
      backSpots.add(FlSpot(x, number(data['backPeakKgf'])));
    }

    final maxY =
        totalSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 40;

    return chartContainer(
      title: selectedMode == 'Team'
          ? 'Team Force Trend'
          : '${selectedSwimmer?['firstName'] ?? 'Swimmer'} Force Trend',
      subtitle: 'Peak force progression across saved tests',
      height: 420,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY < 150 ? 150 : maxY,
          minX: 1,
          maxX: ordered.length.toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: chartTitles(),
          lineBarsData: [
            chartLine(totalSpots, Colors.orange),
            chartLine(frontSpots, const Color(0xFF1976FF)),
            chartLine(backSpots, const Color(0xFF00B8A9)),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Colors.orange, label: 'Total Peak'),
        _LegendItem(color: Color(0xFF1976FF), label: 'Front Peak'),
        _LegendItem(color: Color(0xFF00B8A9), label: 'Back Peak'),
      ],
    );
  }

  Widget asymmetryTrendChart(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final ordered = oldestToNewest(tests);

    final spots = <FlSpot>[];

    for (int i = 0; i < ordered.length; i++) {
      final data = ordered[i].data() as Map<String, dynamic>;
      final front = number(data['balanceFrontPercent']);
      final back = number(data['balanceBackPercent']);

      spots.add(FlSpot((i + 1).toDouble(), (front - back).abs()));
    }

    return chartContainer(
      title: 'Asymmetry Trend',
      subtitle: 'Front/back imbalance over time. Lower is better.',
      height: 360,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 50,
          minX: 1,
          maxX: ordered.length.toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: chartTitles(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 8,
                color: Colors.greenAccent.withOpacity(0.7),
                strokeWidth: 2,
                dashArray: [8, 6],
              ),
              HorizontalLine(
                y: 15,
                color: Colors.orangeAccent.withOpacity(0.7),
                strokeWidth: 2,
                dashArray: [8, 6],
              ),
            ],
          ),
          lineBarsData: [
            chartLine(spots, const Color(0xFF6C4DFF)),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF6C4DFF), label: 'Asymmetry %'),
        _LegendItem(color: Colors.greenAccent, label: 'Good ≤ 8%'),
        _LegendItem(color: Colors.orangeAccent, label: 'Warning ≥ 15%'),
      ],
    );
  }

  LineChartBarData chartLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.10),
      ),
    );
  }

  FlTitlesData chartTitles() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 50,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 34,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '#${value.toInt()}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget chartContainer({
    required String title,
    required String subtitle,
    required double height,
    required Widget child,
    required List<_LegendItem> legend,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          Expanded(child: child),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: legend,
          ),
        ],
      ),
    );
  }

  Widget compareTwoTests(List<QueryDocumentSnapshot> tests) {
    if (tests.length < 2) {
      return infoBox(
        title: 'Compare Two Tests',
        body: 'At least two tests are needed for comparison.',
        icon: Icons.compare_arrows,
      );
    }

final selectedA = findTestById(tests, compareAId) ??
    (tests.length > 1 ? tests[1] : tests.first);

final selectedB = findTestById(tests, compareBId) ?? tests.first;

    final dataA = selectedA.data() as Map<String, dynamic>;
    final dataB = selectedB.data() as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compare Two Tests',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Compare force, RFD, balance, and asymmetry between two tests.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return Column(
                  children: [
                    compareDropdown(
                      label: 'Test A',
                      value: compareAId ?? selectedA.id,
                      tests: tests,
                      onChanged: (value) => setState(() => compareAId = value),
                    ),
                    const SizedBox(height: 14),
                    compareDropdown(
                      label: 'Test B',
                      value: compareBId ?? selectedB.id,
                      tests: tests,
                      onChanged: (value) => setState(() => compareBId = value),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: compareDropdown(
                      label: 'Test A',
                      value: compareAId ?? selectedA.id,
                      tests: tests,
                      onChanged: (value) => setState(() => compareAId = value),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: compareDropdown(
                      label: 'Test B',
                      value: compareBId ?? selectedB.id,
                      tests: tests,
                      onChanged: (value) => setState(() => compareBId = value),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          compareMetrics(dataA, dataB),
        ],
      ),
    );
  }

  Widget compareDropdown({
    required String label,
    required String value,
    required List<QueryDocumentSnapshot> tests,
    required ValueChanged<String?> onChanged,
  }) {
    final ids = tests.map((e) => e.id).toSet();

    final safeValue = ids.contains(value) ? value : tests.first.id;

    return DropdownButtonFormField<String>(
      value: safeValue,
      dropdownColor: const Color(0xFF111C2E),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF061226),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: tests.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return DropdownMenuItem(
          value: doc.id,
          child: Text(
            '${data['swimmerName'] ?? 'Test'} • ${formatShortDate(data)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget compareMetrics(Map<String, dynamic> a, Map<String, dynamic> b) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = [
          compareMetric('Peak', number(a['totalPeakKgf']), number(b['totalPeakKgf']), 'kgf'),
          compareMetric('Front', number(a['frontPeakKgf']), number(b['frontPeakKgf']), 'kgf'),
          compareMetric('Back', number(a['backPeakKgf']), number(b['backPeakKgf']), 'kgf'),
          compareMetric('RFD', number(a['rfdKgfPerSecond']), number(b['rfdKgfPerSecond']), 'kgf/s'),
          compareMetric(
            'Asymmetry',
            (number(a['balanceFrontPercent']) - number(a['balanceBackPercent'])).abs(),
            (number(b['balanceFrontPercent']) - number(b['balanceBackPercent'])).abs(),
            '%',
            lowerIsBetter: true,
          ),
        ];

        if (constraints.maxWidth < 850) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: item,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: item,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget compareMetric(
    String title,
    double a,
    double b,
    String suffix, {
    bool lowerIsBetter = false,
  }) {
    final change = b - a;
    final improved = lowerIsBetter ? change < 0 : change > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF061226),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${a.toStringAsFixed(1)} → ${b.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} $suffix',
            style: TextStyle(
              color: improved ? Colors.greenAccent : Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget forceZonesBox(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    int low = 0;
    int developing = 0;
    int high = 0;
    int elite = 0;

    for (final doc in tests) {
      final data = doc.data() as Map<String, dynamic>;
      final zone = zoneForPeak(number(data['totalPeakKgf']));

      if (zone == 'Low') low++;
      if (zone == 'Developing') developing++;
      if (zone == 'High') high++;
      if (zone == 'Elite') elite++;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Force Zones',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Classification based on total peak force.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 18),
          zoneRow('Elite', elite, Colors.greenAccent),
          zoneRow('High', high, Colors.orangeAccent),
          zoneRow('Developing', developing, const Color(0xFF1976FF)),
          zoneRow('Low', low, Colors.redAccent),
        ],
      ),
    );
  }

  Widget zoneRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Text(
            '$count test${count == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget leaderboard(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final sorted = [...tests];

    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      return number(bData['totalPeakKgf'])
          .compareTo(number(aData['totalPeakKgf']));
    });

    final top = sorted.take(8).toList();

    return Container(
      height: 440,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Peak Force',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Best total peak results',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: top.length,
              itemBuilder: (context, index) {
                final doc = top[index];
                final data = doc.data() as Map<String, dynamic>;

                final name = data['swimmerName'] ?? 'Unknown';
                final peak = number(data['totalPeakKgf']);
                final rfd = number(data['rfdKgfPerSecond']);
                final zone = zoneForPeak(peak);

                return ListTile(
                  onTap: () => openTest(doc),
                  leading: CircleAvatar(
                    backgroundColor:
                        index == 0 ? Colors.orange : const Color(0xFF1976FF),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    name.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${formatDate(data)} • RFD ${rfd.toStringAsFixed(1)} • $zone',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Text(
                    '${peak.toStringAsFixed(1)} kgf',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget alertsBox(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final alerts = <String>[];

    final fatigue = fatigueStatus(tests);

    if (fatigue == 'Fatigue risk') {
      alerts.add('Fatigue risk detected. Latest peak is significantly below recent average.');
    }

    for (final doc in tests.take(8)) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['swimmerName'] ?? 'Unknown';
      final front = number(data['balanceFrontPercent']);
      final back = number(data['balanceBackPercent']);
      final diff = (front - back).abs();

      if (diff >= 15) {
        alerts.add(
          '$name has a ${diff.toStringAsFixed(0)}% front/back imbalance.',
        );
      }
    }

    if (alerts.isEmpty) {
      alerts.add('No major balance or fatigue alerts in the selected data.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coach Alerts',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget latestTests(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

    final latest = tests.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Test Details',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        ...latest.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final name = data['swimmerName'] ?? 'Unknown';
          final peak = number(data['totalPeakKgf']);
          final front = number(data['balanceFrontPercent']);
          final back = number(data['balanceBackPercent']);
          final zone = zoneForPeak(peak);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              onTap: () => openTest(doc),
              leading: CircleAvatar(
                backgroundColor: zoneColor(zone),
                child: const Icon(Icons.show_chart, color: Colors.black),
              ),
              title: Text(
                name.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${formatDate(data)} • Balance ${front.toStringAsFixed(0)} / ${back.toStringAsFixed(0)} • $zone',
                style: const TextStyle(color: Colors.white60),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  Text(
                    '${peak.toStringAsFixed(1)} kgf',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () {
                      PdfReportService.printReport(
                        testData: data,
                        swimmerData: selectedSwimmer,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget infoBox({
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 38, color: Colors.white70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('coaches')
                .doc(uid)
                .collection('tests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Could not load progress:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allTests = snapshot.data!.docs;
              final tests = filterTests(allTests);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pageHeader(),
                  const SizedBox(height: 24),
                  filtersBar(),
                  const SizedBox(height: 24),

                  if (allTests.isEmpty)
                    emptyState()
                  else if (selectedMode == 'Swimmer' && selectedSwimmerId == null)
                    infoBox(
                      title: 'Select Swimmer',
                      body: 'Choose an individual swimmer to view personal trends, comparison, readiness, and fatigue data.',
                      icon: Icons.person_search,
                    )
                  else if (tests.isEmpty)
                    infoBox(
                      title: 'No Tests Found',
                      body: 'No saved tests match this view yet.',
                      icon: Icons.show_chart,
                    )
                  else ...[
                    overviewCards(tests: tests, allTests: allTests),
                    const SizedBox(height: 24),
                    scoringSection(tests),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          return Column(
                            children: [
                              trendChart(tests),
                              const SizedBox(height: 20),
                              asymmetryTrendChart(tests),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: trendChart(tests)),
                            const SizedBox(width: 20),
                            Expanded(child: asymmetryTrendChart(tests)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    compareTwoTests(tests),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          return Column(
                            children: [
                              leaderboard(tests),
                              const SizedBox(height: 20),
                              forceZonesBox(tests),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leaderboard(tests)),
                            const SizedBox(width: 20),
                            Expanded(child: forceZonesBox(tests)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    alertsBox(tests),
                    const SizedBox(height: 24),
                    latestTests(tests),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.show_chart_rounded, size: 60, color: Colors.white70),
          SizedBox(height: 18),
          Text(
            'No progress data yet',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Run and save tests to build swimmer and team trends.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}