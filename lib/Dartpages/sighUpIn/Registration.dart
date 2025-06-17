import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage.dart';

class RegisterScreen extends StatefulWidget {
  static String routeName = "RegisterScreen";

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<String?> _uploadImage(String uid) async {
    if (_selectedImage == null) return null;

    try {
      if (await isConnected()) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg');
        await ref.putFile(_selectedImage!);
        return await ref.getDownloadURL();
      } else {}
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _createUserWithEmailAndPassword();
      await _sendVerificationEmail(userCredential.user!);
      final imageUrl = await _uploadProfileImage(userCredential.user!.uid);
      await _saveUserDataToFirestore(userCredential.user!.uid, imageUrl);
      await _saveImageUrlToSharedPreferences(imageUrl);
      Navigator.pushReplacementNamed(context, '/email-verification');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<UserCredential> _createUserWithEmailAndPassword() async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _sendVerificationEmail(User user) async {
    await user.sendEmailVerification();
  }

  Future<String?> _uploadProfileImage(String uid) async {
    return await _uploadImage(uid);
  }

  Future<void> _saveUserDataToFirestore(String uid, String? imageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': _usernameController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'uid': uid,
      'email': _emailController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'admin': false,
      'imageUrl': imageUrl,
    });
  }

  Future<void> _saveImageUrlToSharedPreferences(String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userImageUrl', imageUrl ?? '');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffECECEC),
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(color: Color(0xff012113)),
        ),
        backgroundColor: Color(0xffECECEC),
        iconTheme: IconThemeData(color: Color(0xff012113)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      backgroundColor: Color(0xffD8E8E0),
                      radius: 40,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Color(0xff012113),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(
                      color: Color(0xff54826D),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff54826D), // لون الحدود عندما لا يكون الحقل في حالة تركيز
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff112E21), // لون الحدود عندما يكون الحقل في حالة تركيز
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(), // هذا يحدد النمط العام للحدود
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a username";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "full Name",
                    labelStyle: TextStyle(color: Color(0xff54826D)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff54826D),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff112E21),
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a full name";
                    }
                    if (value.length < 3) {
                      return "Full name must be at least 3 characters";
                    }
                    if (value.length > 50) {
                      return "Full name must be less than 50 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Color(0xff54826D)),

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff54826D), // لون الحدود عندما لا يكون الحقل في حالة تركيز
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff112E21), // لون الحدود عندما يكون الحقل في حالة تركيز
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(), // هذا يحدد النمط العام للحدود
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an email";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Color(0xff54826D)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff54826D), // لون الحدود عندما لا يكون الحقل في حالة تركيز
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff112E21), // لون الحدود عندما يكون الحقل في حالة تركيز
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(), // هذا يحدد النمط العام للحدود
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(color: Color(0xff54826D)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff54826D),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(
                            0xff112E21), // لون الحدود عندما يكون الحقل في حالة تركيز
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(), // هذا يحدد النمط العام للحدود
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
                    }
                    if (_passwordController.text.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 44),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff03361F), // لون الخلفية الأساسي
                    foregroundColor: Colors
                        .white, // لون النص (وأيقونة loading إذا كانت موجودة)
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      // يمكنك إضافة زوايا دائرية إذا أردت
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4, // ظل الزر
                    shadowColor: Colors.black.withOpacity(0.2), // لون الظل
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // خلفية شفافة
                    foregroundColor: Color(0xff03361F), // لون النص (أخضر داكن)
                    elevation: 0, // إزالة الظل
                    padding: EdgeInsets.zero, // إزالة الحشو الداخلي
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap, // تقليل مساحة الضغط
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0), // لا حواف دائرية
                    ),
                  ),
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline, // وضع خط تحت النص
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
