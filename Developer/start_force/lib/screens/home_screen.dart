import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings_screen.dart';
import 'run_test_screen.dart';
import 'swimmers_screen.dart';
import 'results_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime now = DateTime.now();
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  String formatClock(DateTime dateTime) {
    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $period';
  }

  String formatDate(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061226),
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Widget buildButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(icon, size: 42, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 34, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'coach';

    String firstName = 'Coach';

    if (email.contains('@')) {
      firstName = email.split('@').first;
      if (firstName.contains('.')) {
        firstName = firstName.split('.').first;
      }
      firstName =
          firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 850) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SWIMFORCE +',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Measure. Track. Improve.',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Welcome Coach $firstName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Settings',
                              icon: const Icon(Icons.settings_rounded,
                                  color: Colors.white),
                              onPressed: openSettings,
                            ),
                            IconButton(
                              tooltip: 'Log out',
                              icon: const Icon(Icons.logout_rounded,
                                  color: Colors.white),
                              onPressed: () => logout(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatClock(now),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text(formatDate(now),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SWIMFORCE +',
                                style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 10),
                            Text('Measure. Track. Improve.',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome Coach $firstName',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 18),
                              IconButton(
                                tooltip: 'Settings',
                                icon: const Icon(Icons.settings_rounded,
                                    color: Colors.white),
                                onPressed: openSettings,
                              ),
                              IconButton(
                                tooltip: 'Log out',
                                icon: const Icon(Icons.logout_rounded,
                                    color: Colors.white),
                                onPressed: () => logout(context),
                              ),
                            ],
                          ),
                          Text(formatClock(now),
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          Text(formatDate(now),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white60)),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              buildButton(
                context: context,
                title: 'Run Test',
                subtitle: 'Start a new test',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF1976FF),
                screen: const RunTestScreen(),
              ),
              buildButton(
                context: context,
                title: 'Swimmers',
                subtitle: 'Manage swimmers',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF00B8A9),
                screen: const SwimmersScreen(),
              ),
              buildButton(
                context: context,
                title: 'Results',
                subtitle: 'View test history',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF6C4DFF),
                screen: const ResultsScreen(),
              ),
              buildButton(
                context: context,
                title: 'Progress',
                subtitle: 'Track performance',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFFFF8C1A),
                screen: const ProgressScreen(),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111C2E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Colors.greenAccent),
                    SizedBox(width: 12),
                    Text('Connected to Firebase',
                        style: TextStyle(color: Colors.white70)),
                  ],
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