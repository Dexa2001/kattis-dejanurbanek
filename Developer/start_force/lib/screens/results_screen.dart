import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/stat_card.dart';
import '../services/pdf_report_service.dart';
import '../services/six_fifty_pdf_service.dart';
import 'six_fifty_test_detail_screen.dart';
import 'test_detail_screen.dart';
import '../theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  String selectedType = 'force';
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

    if (parsed != null) {
      return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
    }

    final createdAt = test['createdAt'];
    if (createdAt is Timestamp) {
      return DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toDate());
    }

    return 'Unknown date';
  }

  List<QueryDocumentSnapshot> sortedAndFilteredForce(
    List<QueryDocumentSnapshot> docs,
  ) {
    final filtered =
        docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final swimmerName =
              (data['swimmerName'] ?? '').toString().toLowerCase();

          if (searchText.trim().isEmpty) return true;
          return swimmerName.contains(searchText.toLowerCase());
        }).toList();

    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      if (sortMode == 'Highest Peak') {
        return number(
          bData['totalPeakKgf'],
        ).compareTo(number(aData['totalPeakKgf']));
      }

      if (sortMode == 'Best RFD') {
        return number(
          bData['rfdKgfPerSecond'],
        ).compareTo(number(aData['rfdKgfPerSecond']));
      }

      if (sortMode == 'Best Balance') {
        final aDiff =
            (number(aData['balanceFrontPercent']) -
                    number(aData['balanceBackPercent']))
                .abs();
        final bDiff =
            (number(bData['balanceFrontPercent']) -
                    number(bData['balanceBackPercent']))
                .abs();

        return aDiff.compareTo(bDiff);
      }

      return 0;
    });

    return filtered;
  }

  List<QueryDocumentSnapshot> filteredSixFifty(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final group = (data['groupName'] ?? '').toString().toLowerCase();
      final course = (data['course'] ?? '').toString().toLowerCase();
      final date = (data['testDate'] ?? '').toString().toLowerCase();

      if (searchText.trim().isEmpty) return true;

      final q = searchText.toLowerCase();
      return group.contains(q) || course.contains(q) || date.contains(q);
    }).toList();
  }

  void openForceTest(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestDetailScreen(testData: data, testId: doc.id),
      ),
    );
  }

  void openSixFiftyDetail(String testId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SixFiftyTestDetailScreen(testId: testId, testData: data),
      ),
    );
  }

  Future<void> deleteForceTest(QueryDocumentSnapshot doc) async {
    if (uid == null) return;

    final data = doc.data() as Map<String, dynamic>;
    final swimmerName = data['swimmerName'] ?? 'this test';

    final confirm = await showDeleteDialog(
      title: 'Delete Force Test',
      body: 'Are you sure you want to delete $swimmerName force test?',
    );

    if (!confirm) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
      FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('tests')
          .doc(doc.id),
    );

    final swimmerId = data['swimmerId']?.toString();
    if (swimmerId != null && swimmerId.isNotEmpty) {
      batch.delete(
        FirebaseFirestore.instance
            .collection('coaches')
            .doc(uid)
            .collection('swimmers')
            .doc(swimmerId)
            .collection('tests')
            .doc(doc.id),
      );
    }

    await batch.commit();

    if (!mounted) return;
    showMessage('Force test deleted.');
  }

  Future<void> deleteSixFiftyTest(
    String testId,
    Map<String, dynamic> data,
  ) async {
    if (uid == null) return;

    final confirm = await showDeleteDialog(
      title: 'Delete 6×50 Test',
      body: 'Are you sure you want to delete this 6×50 test?',
    );

    if (!confirm) return;

    final rows = data['rows'] as List<dynamic>? ?? [];
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
      FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('sixFiftyTests')
          .doc(testId),
    );

    for (final item in rows) {
      if (item is! Map) continue;

      final swimmerId = item['swimmerId']?.toString();
      if (swimmerId == null || swimmerId.isEmpty) continue;

      batch.delete(
        FirebaseFirestore.instance
            .collection('coaches')
            .doc(uid)
            .collection('swimmers')
            .doc(swimmerId)
            .collection('sixFiftyTests')
            .doc(testId),
      );
    }

    await batch.commit();

    if (!mounted) return;
    showMessage('6×50 test deleted.');
  }

  Future<bool> showDeleteDialog({
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.darkNavy,
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
            ],
          ),
    );

    return result == true;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            'Results',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget resultTypeSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final cards = [
          typeCard(
            keyValue: 'force',
            title: 'Force Tests',
            subtitle: 'View force plate testing history',
            icon: Icons.bolt,
            color: AppColors.blue,
          ),
          typeCard(
            keyValue: 'sixFifty',
            title: '6×50 Tests',
            subtitle: 'View group swim prediction reports',
            icon: Icons.pool_rounded,
            color: AppColors.teal,
          ),
        ];

        if (compact) {
          return Column(
            children: [cards[0], const SizedBox(height: 14), cards[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget typeCard({
    required String keyValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = selectedType == keyValue;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        setState(() {
          selectedType = keyValue;
          searchText = '';
          sortMode = 'Newest';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.borderStrong : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 38),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.whiteMuted),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget forceAnalytics(List<QueryDocumentSnapshot> tests) {
    if (tests.isEmpty) return const SizedBox();

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
        final cards = [
          StatCard(
            title: 'Total Tests',
            value: '${tests.length}',
            icon: Icons.assignment,
            color: AppColors.blue,
          ),
          StatCard(
            title: 'Best Peak',
            value: '${bestPeak.toStringAsFixed(1)} kgf',
            icon: Icons.bolt,
            color: Colors.orange,
          ),
          StatCard(
            title: 'Best RFD',
            value: '${bestRfd.toStringAsFixed(1)} kgf/s',
            icon: Icons.speed,
            color: AppColors.teal,
          ),
          StatCard(
            title: 'Team Symmetry',
            value: '${teamSymmetry.toStringAsFixed(0)} / 100',
            icon: Icons.balance,
            color: AppColors.purple,
          ),
        ];

        if (constraints.maxWidth < 900) {
          return Column(
            children:
                cards
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
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget sixFiftyAnalytics(List<QueryDocumentSnapshot> tests) {
    int totalSwims = 0;

    for (final doc in tests) {
      final data = doc.data() as Map<String, dynamic>;
      final rows = data['rows'] as List<dynamic>? ?? [];
      totalSwims += rows.length;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          StatCard(
            title: '6×50 Tests',
            value: '${tests.length}',
            icon: Icons.pool_rounded,
            color: AppColors.teal,
          ),
          StatCard(
            title: 'Total Swims',
            value: '$totalSwims',
            icon: Icons.groups_rounded,
            color: AppColors.blue,
          ),
          StatCard(
            title: 'Report Type',
            value: 'Prediction',
            icon: Icons.summarize_rounded,
            color: Colors.orange,
          ),
        ];

        if (constraints.maxWidth < 900) {
          return Column(
            children:
                cards
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
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget filters({required bool includeSort}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          return Column(
            children: [
              searchField(),
              if (includeSort) ...[const SizedBox(height: 12), sortDropdown()],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField()),
            if (includeSort) ...[
              const SizedBox(width: 14),
              SizedBox(width: 230, child: sortDropdown()),
            ],
          ],
        );
      },
    );
  }

  Widget searchField() {
    return TextField(
      onChanged: (value) => setState(() => searchText = value),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        labelText:
            selectedType == 'force'
                ? 'Search swimmer'
                : 'Search group, course, or date',
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget sortDropdown() {
    return DropdownButtonFormField<String>(
      value: sortMode,
      dropdownColor: AppColors.card,
      decoration: InputDecoration(
        labelText: 'Sort By',
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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

  Widget forceResultCard(QueryDocumentSnapshot doc) {
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: () => openForceTest(doc),
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.blue,
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
            style: const TextStyle(color: AppColors.whiteSoft),
          ),
        ),
        isThreeLine: true,
        trailing: actionButtons(
          balanceColor: balanceColor,
          onView: () => openForceTest(doc),
          onPrint: () => PdfReportService.printReport(testData: data),
          onDelete: () => deleteForceTest(doc),
        ),
      ),
    );
  }

  Widget actionButtons({
    required Color balanceColor,
    required VoidCallback onView,
    required VoidCallback onPrint,
    required VoidCallback onDelete,
  }) {
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          tooltip: 'Balance status',
          icon: Icon(Icons.balance, color: balanceColor),
          onPressed: onView,
        ),
        IconButton(
          tooltip: 'Print PDF',
          icon: const Icon(Icons.print, color: AppColors.whiteMuted),
          onPressed: onPrint,
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
        IconButton(
          tooltip: 'View Details',
          icon: const Icon(Icons.chevron_right, color: AppColors.whiteMuted),
          onPressed: onView,
        ),
      ],
    );
  }

  Widget sixFiftyCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rows = data['rows'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: () => openSixFiftyDetail(doc.id, data),
        contentPadding: const EdgeInsets.all(18),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.teal,
          child: Icon(Icons.pool_rounded, color: Colors.white),
        ),
        title: Text(
          '${data['groupName'] ?? 'Group'} • ${data['course'] ?? ''}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${data['testDate'] ?? 'Unknown date'}\n'
            '${rows.length} swimmers saved',
            style: const TextStyle(color: AppColors.whiteSoft),
          ),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'View Report',
              icon: const Icon(Icons.visibility, color: AppColors.whiteMuted),
              onPressed: () => openSixFiftyDetail(doc.id, data),
            ),
            IconButton(
              tooltip: 'Print PDF',
              icon: const Icon(Icons.print, color: AppColors.whiteMuted),
              onPressed: () => SixFiftyPdfService.printReport(testData: data),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => deleteSixFiftyTest(doc.id, data),
            ),
          ],
        ),
      ),
    );
  }

  Widget forceResultsSection() {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('coaches')
              .doc(uid)
              .collection('tests')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorText('Could not load force results:\n${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTests = snapshot.data!.docs;
        final tests = sortedAndFilteredForce(allTests);

        if (allTests.isEmpty) {
          return emptyState(
            title: 'No force results yet',
            body: 'Run and save a force test to start building result history.',
            icon: Icons.bar_chart_rounded,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            forceAnalytics(allTests),
            const SizedBox(height: 24),
            filters(includeSort: true),
            const SizedBox(height: 24),
            Text(
              '${tests.length} result${tests.length == 1 ? '' : 's'} shown',
              style: const TextStyle(color: AppColors.whiteSoft),
            ),
            const SizedBox(height: 14),
            ...tests.map(forceResultCard),
          ],
        );
      },
    );
  }

  Widget sixFiftyResultsSection() {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('coaches')
              .doc(uid)
              .collection('sixFiftyTests')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorText('Could not load 6×50 results:\n${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTests = snapshot.data!.docs;
        final tests = filteredSixFifty(allTests);

        if (allTests.isEmpty) {
          return emptyState(
            title: 'No 6×50 results yet',
            body: 'Save a 6×50 test to view reports here.',
            icon: Icons.pool_rounded,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sixFiftyAnalytics(allTests),
            const SizedBox(height: 24),
            filters(includeSort: false),
            const SizedBox(height: 24),
            Text(
              '${tests.length} 6×50 report${tests.length == 1 ? '' : 's'} shown',
              style: const TextStyle(color: AppColors.whiteSoft),
            ),
            const SizedBox(height: 14),
            dateBubbleRow(tests),
            const SizedBox(height: 18),
            ...tests.map(sixFiftyCard),
          ],
        );
      },
    );
  }

  Widget dateBubbleRow(List<QueryDocumentSnapshot> tests) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tests.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  backgroundColor: AppColors.darkNavy,
                  side: const BorderSide(color: AppColors.borderStrong),
                  avatar: const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.teal,
                  ),
                  label: Text(
                    '${data['testDate'] ?? 'Date'} • ${data['groupName'] ?? 'Group'}',
                  ),
                  onPressed: () => openSixFiftyDetail(doc.id, data),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget errorText(String message) {
    return Text(message, style: const TextStyle(color: Colors.redAccent));
  }

  Widget emptyState({
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: AppColors.whiteMuted),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.whiteMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
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
              resultTypeSelector(),
              const SizedBox(height: 26),
              selectedType == 'force'
                  ? forceResultsSection()
                  : sixFiftyResultsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
