import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/six_fifty_pdf_service.dart';
import 'six_fifty_test_detail_screen.dart';

class SixFiftyTestScreen extends StatefulWidget {
  const SixFiftyTestScreen({super.key});

  @override
  State<SixFiftyTestScreen> createState() => _SixFiftyTestScreenState();
}

class _SixFiftyTestScreenState extends State<SixFiftyTestScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  DateTime testDate = DateTime.now();
  String selectedCourse = 'SCY';
  String selectedGroup = 'Elite';

  bool isSaving = false;
  bool isProgrammaticUpdate = false;

  final List<SixFiftyRowData> rows = [];

  final strokes = ['FR', 'BK', 'BR', 'FLY', 'IM'];
  final intervals = ['@40', '@45', '@50', '@55', '@1:00'];

  String get dateText => DateFormat('MM/dd/yyyy').format(testDate);

  @override
  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  double? parseTime(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  String formatSplitFromDigits(String digits) {
    if (digits.length < 3) return digits;
    final whole = digits.substring(0, digits.length - 2);
    final decimal = digits.substring(digits.length - 2);
    return '$whole.$decimal';
  }

  String formatRaceTime(double seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds - (mins * 60);
    return '$mins:${secs.toStringAsFixed(2).padLeft(5, '0')}';
  }

  double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  SixFiftyCalculations calculate(List<double> times) {
    final middle = times.sublist(1, 5);
    final middleAverage = average(middle);

    final slowerMiddle = [...middle]..sort((a, b) => b.compareTo(a));
    final slowerAverage = average(slowerMiddle.take(2).toList());

    final predictionA = times[0] + times[5] + (2 * middleAverage);
    final predictionB = times[0] + times[5] + (2 * slowerAverage);

    final fastest = times.reduce((a, b) => a < b ? a : b);
    final slowest = times.reduce((a, b) => a > b ? a : b);
    final dropOffPercent = ((slowest - fastest) / fastest) * 100;
    final fatigueIndex = times[5] - times[0];

    return SixFiftyCalculations(
      predictionA: predictionA,
      predictionB: predictionB,
      middleAverage: middleAverage,
      slowerAverage: slowerAverage,
      fastest: fastest,
      slowest: slowest,
      dropOffPercent: dropOffPercent,
      fatigueIndex: fatigueIndex,
    );
  }

  List<double>? completedTimes(SixFiftyRowData row) {
    final values = row.times.map((c) => parseTime(c.text)).toList();
    if (values.any((v) => v == null)) return null;
    return values.map((v) => v!).toList();
  }

  String predictionAText(SixFiftyRowData row) {
    final times = completedTimes(row);
    if (times == null || row.dnc) return '/';
    return formatRaceTime(calculate(times).predictionA);
  }

  String predictionBText(SixFiftyRowData row) {
    final times = completedTimes(row);
    if (times == null || row.dnc) return '/';
    return formatRaceTime(calculate(times).predictionB);
  }

  String rangeText(SixFiftyRowData row) {
    return '${predictionAText(row)} - ${predictionBText(row)}';
  }

  bool hasUnsavedData() {
    for (final row in rows) {
      if (row.dnc) return true;
      if (row.lactate.text.trim().isNotEmpty) return true;
      if (row.notes.text.trim().isNotEmpty) return true;
      for (final controller in row.times) {
        if (controller.text.trim().isNotEmpty) return true;
      }
    }
    return false;
  }

  Future<bool> confirmExit() async {
    if (!hasUnsavedData()) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF061226),
            title: const Text('Exit 6×50 Test?'),
            content: const Text(
              'You have entered data that has not been saved.\n\nAre you sure you want to leave this screen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
    );

    return confirm == true;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: testDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => testDate = picked);
    }
  }

  void loadRows(List<QueryDocumentSnapshot> docs) {
    if (rows.isNotEmpty) return;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      rows.add(
        SixFiftyRowData(
          swimmerId: doc.id,
          swimmerName: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
        ),
      );
    }
  }

  void handleTimeChanged({
    required int rowIndex,
    required int timeIndex,
    required String value,
  }) {
    if (isProgrammaticUpdate) return;

    final clean = value.trim();

    if (clean.contains('.')) {
      setState(() {});
      return;
    }

    final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 4) {
      applyBulkDigits(rowIndex: rowIndex, timeIndex: timeIndex, digits: digits);
    } else {
      setState(() {});
    }
  }

  void applyBulkDigits({
    required int rowIndex,
    required int timeIndex,
    required String digits,
  }) {
    isProgrammaticUpdate = true;

    int currentRow = rowIndex;
    int currentTime = timeIndex;
    int cursor = 0;

    while (cursor + 4 <= digits.length && currentRow < rows.length) {
      final chunk = digits.substring(cursor, cursor + 4);
      rows[currentRow].times[currentTime].text = formatSplitFromDigits(chunk);

      cursor += 4;
      currentTime++;

      if (currentTime >= 6) {
        currentTime = 0;
        currentRow++;
      }
    }

    isProgrammaticUpdate = false;

    setState(() {});

    if (currentRow < rows.length) {
      FocusScope.of(
        context,
      ).requestFocus(rows[currentRow].focusNodes[currentTime]);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  bool validateBeforeSave() {
    int completed = 0;

    for (final row in rows) {
      if (row.dnc) continue;

      final values = row.times.map((c) => parseTime(c.text)).toList();
      final hasAny = values.any((v) => v != null);

      if (!hasAny) continue;

      if (values.any((v) => v == null)) {
        showMessage('${row.swimmerName} is missing one or more 50 times.');
        return false;
      }

      if (values.any((v) => v! < 10 || v > 90)) {
        showMessage('${row.swimmerName} has an invalid split.');
        return false;
      }

      completed++;
    }

    if (completed == 0) {
      showMessage('Enter at least one swimmer before saving.');
      return false;
    }

    return true;
  }

  Future<void> saveTest() async {
    if (uid == null) return;
    if (!validateBeforeSave()) return;

    setState(() => isSaving = true);

    try {
      final groupRef =
          FirebaseFirestore.instance
              .collection('coaches')
              .doc(uid)
              .collection('sixFiftyTests')
              .doc();

      final savedRows = <Map<String, dynamic>>[];

      for (final row in rows) {
        final values = row.times.map((c) => parseTime(c.text)).toList();
        final hasAny = values.any((v) => v != null);

        if (!row.dnc && !hasAny) continue;

        final rowData = <String, dynamic>{
          'swimmerId': row.swimmerId,
          'swimmerName': row.swimmerName,
          'stroke': row.stroke,
          'interval': row.interval,
          'dnc': row.dnc,
          'lactate':
              row.lactate.text.trim() == '/'
                  ? '/'
                  : double.tryParse(row.lactate.text.trim()),
          'notes': row.notes.text.trim(),
          'times': row.dnc ? [] : values.map((v) => v!).toList(),
        };

        if (!row.dnc) {
          final calc = calculate(values.map((v) => v!).toList());

          rowData.addAll({
            'predictionA': calc.predictionA,
            'predictionB': calc.predictionB,
            'predictionAText': formatRaceTime(calc.predictionA),
            'predictionBText': formatRaceTime(calc.predictionB),
            'predictionRange':
                '${formatRaceTime(calc.predictionA)} - ${formatRaceTime(calc.predictionB)}',
            'middleAverage': calc.middleAverage,
            'slowerAverage': calc.slowerAverage,
            'fastest': calc.fastest,
            'slowest': calc.slowest,
            'dropOffPercent': calc.dropOffPercent,
            'fatigueIndex': calc.fatigueIndex,
          });
        }

        savedRows.add(rowData);

        await FirebaseFirestore.instance
            .collection('coaches')
            .doc(uid)
            .collection('swimmers')
            .doc(row.swimmerId)
            .collection('sixFiftyTests')
            .doc(groupRef.id)
            .set({
              ...rowData,
              'groupTestId': groupRef.id,
              'course': selectedCourse,
              'groupName': selectedGroup,
              'testDate': dateText,
              'testDateTimestamp': Timestamp.fromDate(testDate),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      final testData = {
        'course': selectedCourse,
        'groupName': selectedGroup,
        'testDate': dateText,
        'testDateTimestamp': Timestamp.fromDate(testDate),
        'rows': savedRows,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await groupRef.set(testData);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: const Color(0xFF061226),
              title: const Text('6×50 Test Saved'),
              content: Text(
                'You saved the test for:\n\n'
                'Group: $selectedGroup\n'
                'Date: $dateText\n'
                'Course: $selectedCourse\n'
                'Swimmers: ${savedRows.length}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Exit'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await SixFiftyPdfService.printReport(
                      testData: {...testData, 'createdAt': Timestamp.now()},
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Report'),
                ),
              ],
            ),
      );

      clearForm();
    } catch (e) {
      showMessage('Could not save 6×50 test: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void clearForm() {
    for (final row in rows) {
      row.clear();
    }
    setState(() {});
  }

  Future<void> deleteTest(String testId, List<dynamic> savedRows) async {
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF061226),
            title: const Text('Delete Test'),
            content: const Text(
              'Are you sure you want to delete this 6×50 test?',
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

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
      FirebaseFirestore.instance
          .collection('coaches')
          .doc(uid)
          .collection('sixFiftyTests')
          .doc(testId),
    );

    for (final item in savedRows) {
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

  void openDetail(String testId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SixFiftyTestDetailScreen(testId: testId, testData: data),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget topControls(double width) {
    final compact = width < 760;

    final content = [
      ElevatedButton.icon(
        onPressed: pickDate,
        icon: const Icon(Icons.calendar_month),
        label: Text('Date: $dateText'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF241D2D),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
      dropdown(
        label: 'Course',
        value: selectedCourse,
        values: const ['SCY', 'SCM', 'LCM'],
        onChanged: (v) => setState(() => selectedCourse = v!),
      ),
      dropdown(
        label: 'Group',
        value: selectedGroup,
        values: const ['Elite', 'Gold', 'Silver', 'Cardinal', 'Black', 'White'],
        onChanged: (v) => setState(() => selectedGroup = v!),
      ),
      ElevatedButton.icon(
        onPressed: isSaving ? null : saveTest,
        icon: const Icon(Icons.save),
        label: Text(isSaving ? 'Saving...' : 'Save Test'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B8A9),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    content
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: w,
                          ),
                        )
                        .toList(),
              )
              : Row(
                children: [
                  Expanded(child: content[0]),
                  const SizedBox(width: 14),
                  Expanded(child: content[1]),
                  const SizedBox(width: 14),
                  Expanded(child: content[2]),
                  const SizedBox(width: 18),
                  content[3],
                ],
              ),
    );
  }

  Widget dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF111C2E),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF061226),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items:
          values
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget timeField(int rowIndex, int timeIndex, double width) {
    final row = rows[rowIndex];

    return SizedBox(
      width: width,
      child: TextField(
        controller: row.times[timeIndex],
        focusNode: row.focusNodes[timeIndex],
        enabled: !row.dnc,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: (value) {
          handleTimeChanged(
            rowIndex: rowIndex,
            timeIndex: timeIndex,
            value: value,
          );
        },
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: '--',
          filled: true,
          fillColor: const Color(0xFF061226),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget lactateBox(SixFiftyRowData row, double width) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: row.lactate,
        enabled: !row.dnc,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9./]')),
        ],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: '/',
          filled: true,
          fillColor: const Color(0xFF061226),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget rangeBox(SixFiftyRowData row, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF061226),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        rangeText(row),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget desktopTable(double width) {
    final nameWidth = width * 0.13;
    final smallWidth = width * 0.055;
    final selectWidth = width * 0.08;
    final lacWidth = width * 0.055;
    final rangeWidth = width * 0.16;
    final dncWidth = width * 0.055;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          tableHeader(
            nameWidth: nameWidth,
            selectWidth: selectWidth,
            smallWidth: smallWidth,
            lacWidth: lacWidth,
            rangeWidth: rangeWidth,
            dncWidth: dncWidth,
          ),
          const Divider(color: Colors.white24),
          ...List.generate(rows.length, (rowIndex) {
            return tableRow(
              rowIndex: rowIndex,
              nameWidth: nameWidth,
              selectWidth: selectWidth,
              smallWidth: smallWidth,
              lacWidth: lacWidth,
              rangeWidth: rangeWidth,
              dncWidth: dncWidth,
            );
          }),
        ],
      ),
    );
  }

  Widget tableHeader({
    required double nameWidth,
    required double selectWidth,
    required double smallWidth,
    required double lacWidth,
    required double rangeWidth,
    required double dncWidth,
  }) {
    final headers = [
      [nameWidth, 'Name'],
      [selectWidth, 'Stroke'],
      [selectWidth, 'Interval'],
      [smallWidth, '1st'],
      [smallWidth, '2nd'],
      [smallWidth, '3rd'],
      [smallWidth, '4th'],
      [smallWidth, '5th'],
      [smallWidth, '6th'],
      [lacWidth, 'LAC'],
      [rangeWidth, 'Range'],
      [dncWidth, 'DNC'],
    ];

    return Row(
      children:
          headers.map((h) {
            return SizedBox(
              width: h[0] as double,
              child: Text(
                h[1] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget tableRow({
    required int rowIndex,
    required double nameWidth,
    required double selectWidth,
    required double smallWidth,
    required double lacWidth,
    required double rangeWidth,
    required double dncWidth,
  }) {
    final row = rows[rowIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: nameWidth,
            child: Text(
              row.swimmerName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: selectWidth,
            child: dropdown(
              label: '',
              value: row.stroke,
              values: strokes,
              onChanged: (v) => setState(() => row.stroke = v!),
            ),
          ),
          SizedBox(
            width: selectWidth,
            child: dropdown(
              label: '',
              value: row.interval,
              values: intervals,
              onChanged: (v) => setState(() => row.interval = v!),
            ),
          ),
          ...List.generate(6, (i) => timeField(rowIndex, i, smallWidth)),
          lactateBox(row, lacWidth),
          rangeBox(row, rangeWidth),
          SizedBox(
            width: dncWidth,
            child: Checkbox(
              value: row.dnc,
              onChanged: (v) => setState(() => row.dnc = v ?? false),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileCards() {
    return Column(
      children: List.generate(rows.length, (rowIndex) {
        final row = rows[rowIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2E),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.swimmerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: dropdown(
                      label: 'Stroke',
                      value: row.stroke,
                      values: strokes,
                      onChanged: (v) => setState(() => row.stroke = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: dropdown(
                      label: 'Interval',
                      value: row.interval,
                      values: intervals,
                      onChanged: (v) => setState(() => row.interval = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  ...List.generate(6, (i) {
                    return Column(
                      children: [
                        Text(
                          '#${i + 1}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 4),
                        timeField(rowIndex, i, 92),
                      ],
                    );
                  }),
                  Column(
                    children: [
                      const Text(
                        'LAC',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      lactateBox(row, 92),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Range',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      rangeBox(row, 260),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: row.notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              CheckboxListTile(
                value: row.dnc,
                onChanged: (v) => setState(() => row.dnc = v ?? false),
                title: const Text('Did not complete'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget recentTests() {
    if (uid == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('coaches')
                .doc(uid)
                .collection('sixFiftyTests')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent 6×50 Tests',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              if (docs.isEmpty)
                const Text(
                  'No saved 6×50 tests yet.',
                  style: TextStyle(color: Colors.white60),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final savedRows = data['rows'] as List<dynamic>? ?? [];

                  return ListTile(
                    onTap: () => openDetail(doc.id, data),
                    leading: const Icon(Icons.pool, color: Color(0xFF00B8A9)),
                    title: Text(
                      '${data['groupName']} • ${data['course']} • ${data['testDate']}',
                    ),
                    subtitle: Text('${savedRows.length} swimmers saved'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed:
                              () => SixFiftyPdfService.printReport(
                                testData: data,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => deleteTest(doc.id, savedRows),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final width = MediaQuery.of(context).size.width;
    final compact = width < 1350;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);

        final shouldExit = await confirmExit();

        if (!mounted) return;

        if (shouldExit) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF02112B),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('coaches')
                    .doc(uid)
                    .collection('swimmers')
                    .orderBy('lastNameLower')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              loadRows(snapshot.data!.docs);

              return SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);

                            final shouldExit = await confirmExit();

                            if (!mounted) return;

                            if (shouldExit) {
                              navigator.pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '6×50 Test Set',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '#1 from dive • #1–5 to turn • #6 to touch finish',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 22),
                    topControls(width),
                    const SizedBox(height: 24),
                    compact ? mobileCards() : desktopTable(width - 52),
                    const SizedBox(height: 24),
                    recentTests(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SixFiftyRowData {
  final String swimmerId;
  final String swimmerName;

  String stroke = 'FR';
  String interval = '@45';
  bool dnc = false;

  final times = List.generate(6, (_) => TextEditingController());
  final focusNodes = List.generate(6, (_) => FocusNode());

  final lactate = TextEditingController();
  final notes = TextEditingController();

  SixFiftyRowData({required this.swimmerId, required this.swimmerName});

  void clear() {
    stroke = 'FR';
    interval = '@45';
    dnc = false;
    for (final controller in times) {
      controller.clear();
    }
    lactate.clear();
    notes.clear();
  }

  void dispose() {
    for (final controller in times) {
      controller.dispose();
    }
    for (final node in focusNodes) {
      node.dispose();
    }
    lactate.dispose();
    notes.dispose();
  }
}

class SixFiftyCalculations {
  final double predictionA;
  final double predictionB;
  final double middleAverage;
  final double slowerAverage;
  final double fastest;
  final double slowest;
  final double dropOffPercent;
  final double fatigueIndex;

  SixFiftyCalculations({
    required this.predictionA,
    required this.predictionB,
    required this.middleAverage,
    required this.slowerAverage,
    required this.fastest,
    required this.slowest,
    required this.dropOffPercent,
    required this.fatigueIndex,
  });
}
