import 'package:MOLLILE/Dartpages/HomePage/Home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  static String routeName = "RegisterScreen";

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;
  bool _isChecking = false;
  late final User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isChecking = true);
    await _user.reload();
    _isEmailVerified = _user.emailVerified;

    setState(() => _isChecking = false);

    if (_isEmailVerified) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Homepage()));
      }
    } else {
      Future.delayed(const Duration(seconds: 5), _checkEmailVerified);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: _isChecking
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    "A verification email has been sent.\nPlease verify to continue.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkEmailVerified,
                    child: const Text("I've Verified"),
                  ),
                ],
              ),
      ),
    );
  }
}
