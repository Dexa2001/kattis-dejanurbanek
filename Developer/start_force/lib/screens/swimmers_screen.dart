import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'test_detail_screen.dart';
import '../services/pdf_report_service.dart';

class SwimmersScreen extends StatefulWidget {
  const SwimmersScreen({super.key});

  @override
  State<SwimmersScreen> createState() => _SwimmersScreenState();
}

class _SwimmersScreenState extends State<SwimmersScreen> {
  String? selectedSwimmerId;

  final uid = FirebaseAuth.instance.currentUser?.uid;

  double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int calculateAge(String dob) {
    try {
      final parts = dob.split('/');
      final birthDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (_) {
      return 0;
    }
  }

  String formatTestDate(Map<String, dynamic> test) {
    final raw = test['testStartedAt'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');

    if (parsed == null) {
      return 'Unknown date';
    }

    return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
  }

  Future<void> showSwimmerDialog({
    String? swimmerId,
    Map<String, dynamic>? swimmer,
  }) async {
    final receipt = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddEditSwimmerDialog(
        swimmerId: swimmerId,
        swimmer: swimmer,
      ),
    );

    if (!mounted || receipt == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF061226),
        title: Text(
          receipt['mode'] == 'edit' ? 'Swimmer Updated' : 'Swimmer Created',
        ),
        content: Text(
          'Confirmation Receipt\n\n'
          'Name: ${receipt['firstName']} ${receipt['lastName']}\n'
          'DOB: ${receipt['dob']}\n'
          'Age: ${receipt['age']}\n'
          'Front Foot: ${receipt['frontFoot']}\n'
          'Back Foot: ${receipt['backFoot']}\n'
          'Weight: ${receipt['weightLbs']} lbs\n'
          'Height: ${receipt['heightDisplay']}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSwimmer(String swimmerId, String swimmerName) async {
    if (uid == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF061226),
        title: const Text('Delete Swimmer'),
        content: Text(
          'Are you sure you want to delete $swimmerName?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await FirebaseFirestore.instance
        .collection('coaches')
        .doc(uid)
        .collection('swimmers')
        .doc(swimmerId)
        .delete();

    if (!mounted) return;

    setState(() {
      selectedSwimmerId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$swimmerName deleted.')),
    );
  }

  void openTestDetail({
    required Map<String, dynamic> testData,
    required Map<String, dynamic> swimmerData,
    required String testId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestDetailScreen(
          testData: testData,
          swimmerData: swimmerData,
          testId: testId,
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pageHeader(),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('coaches')
                    .doc(uid)
                    .collection('swimmers')
                    .orderBy('lastNameLower')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return errorBox(snapshot.error.toString());
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final swimmers = snapshot.data!.docs;

                  if (swimmers.isEmpty) {
                    return emptyState();
                  }

                  QueryDocumentSnapshot? selectedDoc;

                  if (selectedSwimmerId != null) {
                    final matches =
                        swimmers.where((doc) => doc.id == selectedSwimmerId);

                    if (matches.isNotEmpty) {
                      selectedDoc = matches.first;
                    }
                  }

                  final selectedData = selectedDoc?.data() == null
                      ? null
                      : selectedDoc!.data() as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      selectSwimmerDropdown(swimmers),
                      const SizedBox(height: 28),
                      if (selectedData == null)
                        selectPrompt()
                      else
                        swimmerProfile(
                          selectedData,
                          selectedDoc!.id,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
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
            'Swimmers',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => showSwimmerDialog(),
          icon: const Icon(Icons.person_add),
          label: const Text('Register Swimmer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976FF),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget selectSwimmerDropdown(List<QueryDocumentSnapshot> swimmers) {
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
            const DropdownMenuItem<String>(
              value: 'none',
              child: Text('Select Swimmer'),
            ),
            ...swimmers.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(
                  '${data['firstName']} ${data['lastName']}',
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              if (value == null || value == 'none') {
                selectedSwimmerId = null;
              } else {
                selectedSwimmerId = value;
              }
            });
          },
        ),
      ),
    );
  }

  Widget errorBox(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Error loading swimmers:\n$error',
        style: const TextStyle(color: Colors.redAccent),
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
      child: Column(
        children: [
          const Icon(Icons.pool, size: 60, color: Colors.white70),
          const SizedBox(height: 18),
          const Text(
            'No swimmers added yet',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register your first swimmer to begin tracking force data.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => showSwimmerDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Register Swimmer'),
          ),
        ],
      ),
    );
  }

  Widget selectPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.arrow_drop_down_circle, color: Colors.white70, size: 38),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Select a swimmer to view profile, recent tests, and progress.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget swimmerProfile(Map<String, dynamic> swimmer, String swimmerId) {
    final age = calculateAge(swimmer['dob'] ?? '');

    final heightDisplay = swimmer['heightDisplay'] ?? '-';
    final weightLbs = swimmer['weightLbs'] ?? '-';
    final firstName = swimmer['firstName'] ?? '';
    final lastName = swimmer['lastName'] ?? '';
    final fullName = '$firstName $lastName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 750) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileMainInfo(swimmer, age),
                    const SizedBox(height: 18),
                    profileActionButtons(swimmerId, swimmer, fullName),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: profileMainInfo(swimmer, age)),
                  profileActionButtons(swimmerId, swimmer, fullName),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        swimmerAnalytics(swimmerId),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  recentTestsBox(swimmerId, swimmer),
                  const SizedBox(height: 20),
                  progressChartBox(swimmerId),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: recentTestsBox(swimmerId, swimmer)),
                const SizedBox(width: 20),
                Expanded(child: progressChartBox(swimmerId)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget profileMainInfo(Map<String, dynamic> swimmer, int age) {
    final heightDisplay = swimmer['heightDisplay'] ?? '-';
    final weightLbs = swimmer['weightLbs'] ?? '-';

    return Row(
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFF1976FF),
          child: Icon(Icons.person, size: 46, color: Colors.white),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${swimmer['firstName']} ${swimmer['lastName']}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061226),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      heightDisplay.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$weightLbs lbs',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                'Age: $age',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                'Front foot: ${swimmer['frontFoot']} | Back foot: ${swimmer['backFoot']}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget profileActionButtons(
    String swimmerId,
    Map<String, dynamic> swimmer,
    String fullName,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            showSwimmerDialog(
              swimmerId: swimmerId,
              swimmer: swimmer,
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => deleteSwimmer(swimmerId, fullName),
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  Widget swimmerAnalytics(String swimmerId) {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('swimmers')
          .doc(swimmerId)
          .collection('tests')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final tests = snapshot.data!.docs;

        if (tests.isEmpty) {
          return const SizedBox();
        }

        final latest = tests.first.data() as Map<String, dynamic>;

        final totalPeak = number(latest['totalPeakKgf']);
        final rfd = number(latest['rfdKgfPerSecond']);
        final frontBalance = number(latest['balanceFrontPercent']);
        final backBalance = number(latest['balanceBackPercent']);
        final diff = (frontBalance - backBalance).abs();

        final symmetryScore = (100 - diff).clamp(0, 100).toDouble();
        final readinessScore =
            ((symmetryScore * 0.45) + (rfd.clamp(0, 50) * 1.1)).clamp(0, 100);

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  analyticsCard('Latest Peak', '${totalPeak.toStringAsFixed(1)} kgf',
                      Icons.bolt, const Color(0xFFFF8C1A)),
                  const SizedBox(height: 14),
                  analyticsCard('Symmetry Score', '${symmetryScore.toStringAsFixed(0)} / 100',
                      Icons.balance, const Color(0xFF00B8A9)),
                  const SizedBox(height: 14),
                  analyticsCard('Readiness', '${readinessScore.toStringAsFixed(0)} / 100',
                      Icons.speed, const Color(0xFF1976FF)),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: analyticsCard('Latest Peak', '${totalPeak.toStringAsFixed(1)} kgf',
                      Icons.bolt, const Color(0xFFFF8C1A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: analyticsCard('Symmetry Score', '${symmetryScore.toStringAsFixed(0)} / 100',
                      Icons.balance, const Color(0xFF00B8A9)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: analyticsCard('Readiness', '${readinessScore.toStringAsFixed(0)} / 100',
                      Icons.speed, const Color(0xFF1976FF)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget analyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget recentTestsBox(String swimmerId, Map<String, dynamic> swimmerData) {
    if (uid == null) return const SizedBox();

    return Container(
      height: 430,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coaches')
            .doc(uid)
            .collection('swimmers')
            .doc(swimmerId)
            .collection('tests')
            .orderBy('createdAt', descending: true)
            .limit(8)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Could not load tests:\n${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tests = snapshot.data!.docs;

          if (tests.isEmpty) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Tests',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 18),
                Divider(color: Colors.white12),
                SizedBox(height: 14),
                Text(
                  'No test results yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 17),
                ),
                SizedBox(height: 8),
                Text(
                  'Run a test and saved results will show here.',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Tests',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: tests.length,
                  itemBuilder: (context, index) {
                    final doc = tests[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return testCard(
                      testId: doc.id,
                      testData: data,
                      swimmerData: swimmerData,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget testCard({
    required String testId,
    required Map<String, dynamic> testData,
    required Map<String, dynamic> swimmerData,
  }) {
    final totalPeak = number(testData['totalPeakKgf']);
    final rfd = number(testData['rfdKgfPerSecond']);
    final frontBalance = number(testData['balanceFrontPercent']);
    final backBalance = number(testData['balanceBackPercent']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF061226),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: () {
          openTestDetail(
            testData: testData,
            swimmerData: swimmerData,
            testId: testId,
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1976FF),
          child: Icon(Icons.analytics, color: Colors.white),
        ),
        title: Text(
          '${totalPeak.toStringAsFixed(1)} kgf peak',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatTestDate(testData)}\nBalance ${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)} • RFD ${rfd.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white60),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(
              tooltip: 'Print PDF',
              icon: const Icon(Icons.print),
              onPressed: () {
                PdfReportService.printReport(
                  testData: testData,
                  swimmerData: swimmerData,
                );
              },
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget progressChartBox(String swimmerId) {
    if (uid == null) return const SizedBox();

    return Container(
      height: 430,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coaches')
            .doc(uid)
            .collection('swimmers')
            .doc(swimmerId)
            .collection('tests')
            .orderBy('createdAt')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Could not load chart:\n${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tests = snapshot.data!.docs;

          if (tests.isEmpty) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Chart',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 18),
                Text(
                  'No test data yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            );
          }

          final frontSpots = <FlSpot>[];
          final backSpots = <FlSpot>[];
          final totalSpots = <FlSpot>[];

          for (int i = 0; i < tests.length; i++) {
            final data = tests[i].data() as Map<String, dynamic>;
            final x = (i + 1).toDouble();

            frontSpots.add(FlSpot(x, number(data['frontPeakKgf'])));
            backSpots.add(FlSpot(x, number(data['backPeakKgf'])));
            totalSpots.add(FlSpot(x, number(data['totalPeakKgf'])));
          }

          final maxY = totalSpots
                  .map((spot) => spot.y)
                  .fold<double>(0, (a, b) => b > a ? b : a) +
              30;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress Chart',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Peak force trend over time',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY < 150 ? 150 : maxY,
                    minX: 1,
                    maxX: tests.length.toDouble(),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: frontSpots,
                        isCurved: true,
                        color: const Color(0xFF1976FF),
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: backSpots,
                        isCurved: true,
                        color: const Color(0xFF00B8A9),
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                      LineChartBarData(
                        spots: totalSpots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF1976FF), size: 12),
                  SizedBox(width: 6),
                  Text('Front'),
                  SizedBox(width: 16),
                  Icon(Icons.circle, color: Color(0xFF00B8A9), size: 12),
                  SizedBox(width: 6),
                  Text('Back'),
                  SizedBox(width: 16),
                  Icon(Icons.circle, color: Colors.orange, size: 12),
                  SizedBox(width: 6),
                  Text('Total'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddEditSwimmerDialog extends StatefulWidget {
  final String? swimmerId;
  final Map<String, dynamic>? swimmer;

  const AddEditSwimmerDialog({
    super.key,
    this.swimmerId,
    this.swimmer,
  });

  @override
  State<AddEditSwimmerDialog> createState() => _AddEditSwimmerDialogState();
}

class _AddEditSwimmerDialogState extends State<AddEditSwimmerDialog> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final dob = TextEditingController();
  final weight = TextEditingController();

  int heightFeet = 5;
  int heightInches = 6;

  String frontFoot = 'Left';
  String backFoot = 'Right';

  bool isSaving = false;

  bool get isEdit => widget.swimmerId != null;

  @override
  void initState() {
    super.initState();

    final swimmer = widget.swimmer;

    if (swimmer != null) {
      firstName.text = swimmer['firstName']?.toString() ?? '';
      lastName.text = swimmer['lastName']?.toString() ?? '';
      dob.text = swimmer['dob']?.toString() ?? '';
      weight.text = swimmer['weightLbs']?.toString() ?? '';

      heightFeet = swimmer['heightFeet'] ?? 5;
      heightInches = swimmer['heightInches'] ?? 6;

      frontFoot = swimmer['frontFoot'] ?? 'Left';
      backFoot = swimmer['backFoot'] ?? 'Right';
    }
  }

  String capitalizeName(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return '';

    return trimmed
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) {
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      dob.text =
          '${selected.month.toString().padLeft(2, '0')}/${selected.day.toString().padLeft(2, '0')}/${selected.year}';
    }
  }

  int calculateAge(String dobValue) {
    try {
      final parts = dobValue.split('/');
      final birthDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> isDuplicateName({
    required String uid,
    required String first,
    required String last,
  }) async {
    final normalizedName = '${first.toLowerCase()} ${last.toLowerCase()}';

    final snapshot = await FirebaseFirestore.instance
        .collection('coaches')
        .doc(uid)
        .collection('swimmers')
        .where('normalizedName', isEqualTo: normalizedName)
        .get();

    if (snapshot.docs.isEmpty) return false;

    if (isEdit &&
        snapshot.docs.length == 1 &&
        snapshot.docs.first.id == widget.swimmerId) {
      return false;
    }

    return true;
  }

  Future<void> saveSwimmer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final cleanFirstName = capitalizeName(firstName.text);
    final cleanLastName = capitalizeName(lastName.text);

    if (cleanFirstName.isEmpty ||
        cleanLastName.isEmpty ||
        dob.text.trim().isEmpty ||
        weight.text.trim().isEmpty) {
      showMessage('Please complete all required fields.');
      return;
    }

    final weightValue = int.tryParse(weight.text.trim());

    if (weightValue == null || weightValue < 40 || weightValue > 400) {
      showMessage('Please enter a valid weight between 40 and 400 lbs.');
      return;
    }

    final age = calculateAge(dob.text.trim());

    if (age <= 0) {
      showMessage('Please enter a valid date of birth.');
      return;
    }

    if (frontFoot == backFoot) {
      showMessage('Front foot and back foot cannot be the same.');
      return;
    }

    final duplicate = await isDuplicateName(
      uid: uid,
      first: cleanFirstName,
      last: cleanLastName,
    );

    if (duplicate) {
      showMessage('This swimmer already exists.');
      return;
    }

    setState(() => isSaving = true);

    final heightDisplay = '$heightFeet ft $heightInches in';
    final heightTotalInches = (heightFeet * 12) + heightInches;
    final normalizedName =
        '${cleanFirstName.toLowerCase()} ${cleanLastName.toLowerCase()}';

    final swimmerData = {
      'firstName': cleanFirstName,
      'lastName': cleanLastName,
      'firstNameLower': cleanFirstName.toLowerCase(),
      'lastNameLower': cleanLastName.toLowerCase(),
      'normalizedName': normalizedName,
      'dob': dob.text.trim(),
      'ageAtRegistration': age,
      'frontFoot': frontFoot,
      'backFoot': backFoot,
      'weightLbs': weightValue,
      'heightFeet': heightFeet,
      'heightInches': heightInches,
      'heightTotalInches': heightTotalInches,
      'heightDisplay': heightDisplay,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref = FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('swimmers');

      if (isEdit) {
        await ref.doc(widget.swimmerId).update(swimmerData);
      } else {
        await ref.add({
          ...swimmerData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context, {
        ...swimmerData,
        'age': age,
        'mode': isEdit ? 'edit' : 'create',
      });
    } catch (e) {
      showMessage('Could not save swimmer: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    dob.dispose();
    weight.dispose();
    super.dispose();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool numbersOnly = false,
    int? maxLength,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
      inputFormatters:
          numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: icon == null ? null : Icon(icon),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF111C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget dropdownBox({
    required String label,
    required int value,
    required List<int> values,
    required ValueChanged<int?> onChanged,
    required String suffix,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: const Color(0xFF111C2E),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF111C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<int>(
              value: item,
              child: Text('$item $suffix'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF061226),
      title: Text(isEdit ? 'Edit Swimmer' : 'Register Swimmer'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 620,
          child: Column(
            children: [
              sectionTitle('Basic Information'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: field(
                      firstName,
                      'First Name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field(
                      lastName,
                      'Last Name',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: dob,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.cake_outlined),
                  labelText: 'DOB MM/DD/YYYY',
                  filled: true,
                  fillColor: const Color(0xFF111C2E),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: pickDate,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              sectionTitle('Body Measurements'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: field(
                      weight,
                      'Weight lbs',
                      numbersOnly: true,
                      maxLength: 3,
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: dropdownBox(
                      label: 'Height Feet',
                      value: heightFeet,
                      values: List.generate(5, (index) => index + 4),
                      suffix: 'ft',
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => heightFeet = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: dropdownBox(
                      label: 'Height Inches',
                      value: heightInches,
                      values: List.generate(12, (index) => index),
                      suffix: 'in',
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => heightInches = value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              sectionTitle('Start Position'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: frontFoot,
                      dropdownColor: const Color(0xFF111C2E),
                      decoration: InputDecoration(
                        labelText: 'Front Foot',
                        filled: true,
                        fillColor: const Color(0xFF111C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Left', child: Text('Left')),
                        DropdownMenuItem(value: 'Right', child: Text('Right')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          frontFoot = value;
                          backFoot = value == 'Left' ? 'Right' : 'Left';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: backFoot,
                      dropdownColor: const Color(0xFF111C2E),
                      decoration: InputDecoration(
                        labelText: 'Back Foot',
                        filled: true,
                        fillColor: const Color(0xFF111C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Left', child: Text('Left')),
                        DropdownMenuItem(value: 'Right', child: Text('Right')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          backFoot = value;
                          frontFoot = value == 'Left' ? 'Right' : 'Left';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isSaving ? null : saveSwimmer,
          icon: Icon(isEdit ? Icons.save : Icons.person_add),
          label: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(isEdit ? 'Save Changes' : 'Save Swimmer'),
        ),
      ],
    );
  }
}