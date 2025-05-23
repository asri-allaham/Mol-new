import 'package:flutter/material.dart';
import '../CustomWidget/buttom.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});
  static String IDPuchName = "ForgotPassword";

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendResetLink(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Reset link sent to $email"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ ${e.message ?? 'Failed to send reset link'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffECECEC),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 151),
                    Text(
                      "Forgot Password",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Please enter your email to reset the password",
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF54826D),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Your Email",
                      style: TextStyle(fontSize: 19, color: Color(0xff012113)),
                    ),
                    SizedBox(
                      width: 350,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "example@gmail.com",
                          hintStyle: TextStyle(color: Color(0xFF54826D)),
                          filled: true,
                          fillColor: const Color(0xffECECEC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xff012113),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xff012113),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    GradientButton(
                      text: "RESET PASSWORD",
                      width: 350,
                      fontSize: 15,
                      onTap: () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Please enter a valid email"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        await _sendResetLink(email);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 83,
            left: 26,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF54826D)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
