import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/sighUpIn/Forgot_password.dart';
import 'package:Mollni/Dartpages/sighUpIn/Registration.dart';
import 'package:Mollni/Dartpages/sighUpIn/login_state.dart';
import 'package:Mollni/simple_functions/botton.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String IDPuchName = "LoginPage";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isChecked = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!(userCredential.user?.emailVerified ?? false)) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please verify your email first. Check your inbox.'),
            ),
          );
        }
        return;
      }

      Provider.of<LoginState>(context, listen: false).login();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => Homepage()));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      }
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$errorMessage $e")),
        );
      }
    } catch (e) {
      print("Unknown error: $e");
      SnackBar(content: Text("$e"));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      Provider.of<LoginState>(context, listen: false).login();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => Homepage()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff012113)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xffECECEC),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xffECECEC),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              _buildSectionTitle("WELCOME BACK", fontSize: 17),
              _buildSectionTitle("Log In Your Account",
                  fontSize: 30, isBold: true),
              const SizedBox(height: 35),
              _buildInputLabel("Your Email"),
              _buildTextField(
                controller: _emailController,
                hintText: "name@gmail.com",
                hintColor: Color(0xff90AC9F),
              ),
              const SizedBox(height: 15),
              _buildInputLabel("Password"),
              _buildTextField(
                controller: _passwordController,
                hintText: "**********",
                hintColor: Color(0xff54826D),
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xff54826D),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => ForgotPassword()));
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xff012113),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildRadioButton("Business owner"),
              _buildRadioButton("Investor"),
              const SizedBox(height: 25),
              GradientButton(
                text: "CONTINUE",
                width: 350,
                fontSize: 15,
                onTap: () {
                  _login();
                },
              ),
              const SizedBox(height: 30),
              _buildOrDivider(),
              const SizedBox(height: 40),
              _buildGoogleLoginButton(),
              const SizedBox(height: 40),
              _buildSignUpSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text,
      {double fontSize = 17, bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: const Color(0xff012113),
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 19, color: Color(0xff012113)),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? hintText,
    Color? hintColor,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
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
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildRadioButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          // CustomRadioButton(text: text), come back later
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xffABBEB5)),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: const Color(0xffABBEB5),
          ),
          height: 30,
          width: 69,
          child: const Center(
            child: Text(
              "OR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xffABBEB5)),
        ),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: _isLoading ? null : signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffABBEB5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xffABBEB5), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/Images/google_logo.png',
              height: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              "Sign in with Google",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xff012113),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(fontSize: 15, color: Color(0xff012113)),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xff54826D),
            ),
          ),
        ),
      ],
    );
  }
}
