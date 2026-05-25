import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('coaches')
                  .doc(user.uid)
                  .snapshots(),
          builder: (context, coachSnapshot) {
            if (coachSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!coachSnapshot.hasData || !coachSnapshot.data!.exists) {
              return const PendingApprovalScreen(
                message:
                    'Your coach profile was not found. Please contact SwimForce+ support.',
              );
            }

            final data = coachSnapshot.data!.data() as Map<String, dynamic>;
            final approved = data['approved'] == true;

            if (!approved) {
              return const PendingApprovalScreen(
                message:
                    'Your account is pending approval. You will be able to access SwimForce+ once your account is approved.',
              );
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  final String message;

  const PendingApprovalScreen({super.key, required this.message});

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02112B),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  size: 64,
                  color: Color(0xFFFF8C1A),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pending Approval',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
