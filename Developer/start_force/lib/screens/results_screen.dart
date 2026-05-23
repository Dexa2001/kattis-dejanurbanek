import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'test_detail_screen.dart';
import '../services/pdf_report_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  String searchText = '';
  String sortMode = 'Newest';

  double number(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatDate(Map<String, dynamic> test) {
    final raw = test['testStartedAt'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');

    if (parsed == null) return 'Unknown date';

    return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
  }

  List<QueryDocumentSnapshot> sortedAndFiltered(List<QueryDocumentSnapshot> docs) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final swimmerName = (data['swimmerName'] ?? '').toString().toLowerCase();

      if (searchText.trim().isEmpty) return true;

      return swimmerName.contains(searchText.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      if (sortMode == 'Highest Peak') {
        return number(bData['totalPeakKgf']).compareTo(number(aData['totalPeakKgf']));
      }

      if (sortMode == 'Best RFD') {
        return number(bData['rfdKgfPerSecond']).compareTo(number(aData['rfdKgfPerSecond']));
      }

      if (sortMode == 'Best Balance') {
        final aDiff = (number(aData['balanceFrontPercent']) -
                number(aData['balanceBackPercent']))
            .abs();
        final bDiff = (number(bData['balanceFrontPercent']) -
                number(bData['balanceBackPercent']))
            .abs();

        return aDiff.compareTo(bDiff);
      }

      return 0;
    });

    return filtered;
  }

  void openTest(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestDetailScreen(
          testData: data,
          testId: doc.id,
        ),
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget topAnalytics(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) {
      return const SizedBox();
    }

    double bestPeak = 0;
    double bestRfd = 0;
    double balanceTotal = 0;

    for (final doc in tests) {
      final data = doc.data() as Map<String, dynamic>;

      final peak = number(data['totalPeakKgf']);
      final rfd = number(data['rfdKgfPerSecond']);
      final front = number(data['balanceFrontPercent']);
      final back = number(data['balanceBackPercent']);

      if (peak > bestPeak) bestPeak = peak;
      if (rfd > bestRfd) bestRfd = rfd;

      balanceTotal += (front - back).abs();
    }

    final avgBalanceDiff = balanceTotal / tests.length;
    final teamSymmetry = (100 - avgBalanceDiff).clamp(0, 100).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              statCard('Total Tests', '${tests.length}', Icons.assignment, const Color(0xFF1976FF)),
              const SizedBox(height: 14),
              statCard('Best Peak', '${bestPeak.toStringAsFixed(1)} kgf', Icons.bolt, Colors.orange),
              const SizedBox(height: 14),
              statCard('Best RFD', '${bestRfd.toStringAsFixed(1)} kgf/s', Icons.speed, const Color(0xFF00B8A9)),
              const SizedBox(height: 14),
              statCard('Team Symmetry', '${teamSymmetry.toStringAsFixed(0)} / 100', Icons.balance, const Color(0xFF6C4DFF)),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: statCard('Total Tests', '${tests.length}', Icons.assignment, const Color(0xFF1976FF))),
            const SizedBox(width: 14),
            Expanded(child: statCard('Best Peak', '${bestPeak.toStringAsFixed(1)} kgf', Icons.bolt, Colors.orange)),
            const SizedBox(width: 14),
            Expanded(child: statCard('Best RFD', '${bestRfd.toStringAsFixed(1)} kgf/s', Icons.speed, const Color(0xFF00B8A9))),
            const SizedBox(width: 14),
            Expanded(child: statCard('Team Symmetry', '${teamSymmetry.toStringAsFixed(0)} / 100', Icons.balance, const Color(0xFF6C4DFF))),
          ],
        );
      },
    );
  }

  Widget filters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          return Column(
            children: [
              searchField(),
              const SizedBox(height: 12),
              sortDropdown(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField()),
            const SizedBox(width: 14),
            SizedBox(width: 230, child: sortDropdown()),
          ],
        );
      },
    );
  }

  Widget searchField() {
    return TextField(
      onChanged: (value) {
        setState(() => searchText = value);
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        labelText: 'Search swimmer',
        filled: true,
        fillColor: const Color(0xFF111C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget sortDropdown() {
    return DropdownButtonFormField<String>(
      value: sortMode,
      dropdownColor: const Color(0xFF111C2E),
      decoration: InputDecoration(
        labelText: 'Sort By',
        filled: true,
        fillColor: const Color(0xFF111C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Newest', child: Text('Newest')),
        DropdownMenuItem(value: 'Highest Peak', child: Text('Highest Peak')),
        DropdownMenuItem(value: 'Best RFD', child: Text('Best RFD')),
        DropdownMenuItem(value: 'Best Balance', child: Text('Best Balance')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => sortMode = value);
      },
    );
  }

  Widget resultCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final swimmerName = data['swimmerName'] ?? 'Unknown Swimmer';
    final totalPeak = number(data['totalPeakKgf']);
    final frontPeak = number(data['frontPeakKgf']);
    final backPeak = number(data['backPeakKgf']);
    final rfd = number(data['rfdKgfPerSecond']);
    final frontBalance = number(data['balanceFrontPercent']);
    final backBalance = number(data['balanceBackPercent']);
    final balanceDiff = (frontBalance - backBalance).abs();

    final balanceColor =
        balanceDiff <= 8 ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: () => openTest(doc),
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1976FF),
          child: Text(
            swimmerName.toString().isEmpty
                ? '?'
                : swimmerName.toString()[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          swimmerName.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${formatDate(data)}\n'
            'Peak: ${totalPeak.toStringAsFixed(1)} kgf • RFD: ${rfd.toStringAsFixed(1)} kgf/s\n'
            'Front ${frontPeak.toStringAsFixed(1)} / Back ${backPeak.toStringAsFixed(1)} • Balance ${frontBalance.toStringAsFixed(0)} / ${backBalance.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 6,
          children: [
            Icon(Icons.balance, color: balanceColor),
            IconButton(
              tooltip: 'Print PDF',
              icon: const Icon(Icons.print),
              onPressed: () {
                PdfReportService.printReport(testData: data);
              },
            ),
            const Icon(Icons.chevron_right),
          ],
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
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Results',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('coaches')
                    .doc(uid)
                    .collection('tests')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Could not load results:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allTests = snapshot.data!.docs;
                  final tests = sortedAndFiltered(allTests);

                  if (allTests.isEmpty) {
                    return emptyState();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      topAnalytics(allTests),
                      const SizedBox(height: 24),
                      filters(),
                      const SizedBox(height: 24),
                      Text(
                        '${tests.length} result${tests.length == 1 ? '' : 's'} shown',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 14),
                      ...tests.map(resultCard),
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
          Icon(Icons.bar_chart_rounded, size: 60, color: Colors.white70),
          SizedBox(height: 18),
          Text(
            'No results yet',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Run and save a test to start building result history.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}