import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );

    slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );

    animationController.forward();
  }

  String backgroundImage(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (width < 700) {
      return 'assets/images/login_bg_mobile_9x16.png';
    }

    if (height > width * 0.8) {
      return 'assets/images/login_bg_tablet_4x3.png';
    }

    return 'assets/images/login_bg_web_16x9.png';
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login failed.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void showRegisterDialog() {
    showDialog(context: context, builder: (_) => const CoachRegisterDialog());
  }

  void showResetPasswordDialog() {
    showDialog(context: context, builder: (_) => const ResetPasswordDialog());
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 600;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage(context),
              fit: BoxFit.cover,
              alignment: compact ? Alignment.centerRight : Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    compact
                        ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF061226).withValues(alpha: 0.78),
                            const Color(0xFF061226).withValues(alpha: 0.82),
                            const Color(0xFF061226).withValues(alpha: 0.94),
                          ],
                        )
                        : LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFF061226).withValues(alpha: 0.95),
                            const Color(0xFF061226).withValues(alpha: 0.78),
                            const Color(0xFF061226).withValues(alpha: 0.35),
                          ],
                        ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 20 : 28,
                  vertical: compact ? 18 : 28,
                ),
                child: Align(
                  alignment: compact ? Alignment.center : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 430 : 480),
                    child: AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, slideAnimation.value),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 24 : 28),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF061226,
                          ).withValues(alpha: 0.80),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SWIMFORCE+',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: compact ? 42 : 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Measure. Analyze. Improve.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Coach login',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white60,
                              ),
                            ),
                            SizedBox(height: compact ? 30 : 36),
                            inputField(
                              controller: emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 18),
                            inputField(
                              controller: passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: true,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 62,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text(
                                          'LOG IN',
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: showRegisterDialog,
                              child: const Text(
                                'Need an account? Register as coach',
                              ),
                            ),
                            TextButton(
                              onPressed: showResetPasswordDialog,
                              child: const Text(
                                'Forgot password? Reset by email',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF111C2E).withValues(alpha: 0.92),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class CoachRegisterDialog extends StatefulWidget {
  const CoachRegisterDialog({super.key});

  @override
  State<CoachRegisterDialog> createState() => _CoachRegisterDialogState();
}

class _CoachRegisterDialogState extends State<CoachRegisterDialog> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final dob = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLoading = false;

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      dob.text =
          '${selected.month.toString().padLeft(2, '0')}/${selected.day.toString().padLeft(2, '0')}/${selected.year}';
    }
  }

  Future<void> registerCoach() async {
    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('coaches').doc(uid).set({
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'dob': dob.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'role': 'coach',
        'approved': false,
        'status': 'pending',
        'approvedAt': null,
        'approvedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Registration failed.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    dob.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF111C2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget responsiveRow(List<Widget> children) {
    final width = MediaQuery.of(context).size.width;

    if (width < 620) {
      return Column(
        children:
            children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                )
                .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 700 ? width * 0.9 : 460.0;

    return AlertDialog(
      backgroundColor: const Color(0xFF061226),
      title: const Text('Register as Coach'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: dialogWidth,
          child: Column(
            children: [
              responsiveRow([
                field(firstName, 'First Name'),
                field(lastName, 'Last Name'),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: dob,
                decoration: InputDecoration(
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
              const SizedBox(height: 14),
              field(phone, 'Phone Number'),
              const SizedBox(height: 14),
              field(email, 'Email'),
              const SizedBox(height: 14),
              field(password, 'Password', obscure: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : registerCoach,
          child:
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Account'),
        ),
      ],
    );
  }
}

class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final email = TextEditingController();
  bool isLoading = false;

  Future<void> sendReset() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not send reset email.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: const Color(0xFF061226),
      title: const Text('Reset Password'),
      content: SizedBox(
        width: width < 700 ? width * 0.86 : 420,
        child: TextField(
          controller: email,
          decoration: InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: const Color(0xFF111C2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : sendReset,
          child:
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}
