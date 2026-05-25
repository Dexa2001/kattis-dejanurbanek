import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'progress_screen.dart';
import 'results_screen.dart';
import 'run_test_screen.dart';
import 'settings_screen.dart';
import 'six_fifty_test_screen.dart';
import 'swimmers_screen.dart';

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
      setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void openSettings() {
    openScreen(const SettingsScreen());
  }

  String formatClock(DateTime dateTime) {
    int hour = dateTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $period';
  }

  String formatDate(DateTime dateTime) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String coachFirstName() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'coach';

    var firstName = 'Coach';

    if (email.contains('@')) {
      firstName = email.split('@').first;

      if (firstName.contains('.')) {
        firstName = firstName.split('.').first;
      }

      if (firstName.isNotEmpty) {
        firstName =
            firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
      }
    }

    return firstName;
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

  Widget iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: compact ? 48 : 54,
        width: compact ? 48 : 54,
        decoration: BoxDecoration(
          color: const Color(0xFF111C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: compact ? 24 : 28),
        ),
      ),
    );
  }

  Widget header(bool compact) {
    final firstName = coachFirstName();

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SWIMFORCE +',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              iconButton(
                icon: Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: openSettings,
                compact: true,
              ),
              const SizedBox(width: 8),
              iconButton(
                icon: Icons.logout_rounded,
                tooltip: 'Log out',
                onPressed: () => logout(context),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Measure. Track. Improve.\nWelcome Coach $firstName',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              timeTextBlock(),
            ],
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
              Text(
                'SWIMFORCE +',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Measure. Track. Improve.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                iconButton(
                  icon: Icons.settings_rounded,
                  tooltip: 'Settings',
                  onPressed: openSettings,
                ),
                const SizedBox(width: 10),
                iconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Log out',
                  onPressed: () => logout(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            timeCard(alignment: CrossAxisAlignment.end),
          ],
        ),
      ],
    );
  }

  Widget timeTextBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatClock(now),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          formatDate(now),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget timeCard({required CrossAxisAlignment alignment}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            formatClock(now),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            formatDate(now),
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
    bool featured = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => openScreen(screen),
      child: Container(
        padding: EdgeInsets.all(featured ? 22 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, const Color(0xFF061226), 0.18)!],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final veryCompact = constraints.maxWidth < 360;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: featured ? 58 : 52,
                      width: featured ? 58 : 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        icon,
                        size: featured ? 34 : 30,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: veryCompact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: featured ? 27 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget dashboardGrid(double width) {
    final cards = [
      dashboardCard(
        title: 'Run Force Test',
        subtitle: 'Start force plate testing',
        icon: Icons.play_arrow_rounded,
        color: const Color(0xFF1976FF),
        screen: const RunTestScreen(),
        featured: true,
      ),
      dashboardCard(
        title: '6×50 Test Set',
        subtitle: 'Group swim prediction test',
        icon: Icons.pool_rounded,
        color: const Color(0xFF00B8A9),
        screen: const SixFiftyTestScreen(),
        featured: true,
      ),
      dashboardCard(
        title: 'Swimmers',
        subtitle: 'Manage roster and profiles',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF00A0C6),
        screen: const SwimmersScreen(),
      ),
      dashboardCard(
        title: 'Results',
        subtitle: 'View testing history',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF6C4DFF),
        screen: const ResultsScreen(),
      ),
      dashboardCard(
        title: 'Progress',
        subtitle: 'Track trends and readiness',
        icon: Icons.show_chart_rounded,
        color: const Color(0xFFFF8C1A),
        screen: const ProgressScreen(),
      ),
      dashboardCard(
        title: 'Settings',
        subtitle: 'Sensors, BLE, calibration',
        icon: Icons.tune_rounded,
        color: const Color(0xFF334155),
        screen: const SettingsScreen(),
      ),
    ];

    int crossAxisCount;
    double ratio;

    if (width < 650) {
      crossAxisCount = 1;
      ratio = 2.05;
    } else if (width < 1050) {
      crossAxisCount = 2;
      ratio = 1.45;
    } else {
      crossAxisCount = 3;
      ratio = 1.35;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: ratio,
      children: cards,
    );
  }

  Widget statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_done_rounded, color: Colors.greenAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connected to Firebase',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Icon(Icons.verified_rounded, color: Colors.white30),
        ],
      ),
    );
  }

  Widget tipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFF8C1A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'SwimForce+ • v1.2 • Est. 2024',
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 850;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width < 500 ? 15 : 24,
            vertical: width < 500 ? 18 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(compact),
              const SizedBox(height: 26),
              dashboardGrid(width),
              const SizedBox(height: 22),
              tipCard(),
              const SizedBox(height: 16),
              statusCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
