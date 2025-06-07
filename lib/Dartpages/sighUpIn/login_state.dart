import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginState with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userImageUrl;

  bool get isLoggedIn => _isLoggedIn;
  String? get userImageUrl => _userImageUrl;

  LoginState() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (_isLoggedIn) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print("Logged-in user UID: ${user.uid}");

          try {
            print("Fetching user data from Firestore...");
            final userData = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            if (userData.exists) {
              print("User data found: ${userData.data()}");
              _userImageUrl = userData.data()?['imageUrl'];
            } else {
              print("No user data found for UID: ${user.uid}");
              // Optionally create the document if it doesn't exist
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'imageUrl': ''});
              _userImageUrl = '';
            }
          } catch (e) {
            print("Error fetching user data: $e");
          }
        } else {
          print("No user is currently logged in.");
        }
      } else {
        _userImageUrl = prefs.getString('userImageUrl');
        print("User is not logged in. Using cached image URL: $_userImageUrl");
      }
    } catch (e) {
      print("Error loading login state: $e");
    }

    notifyListeners();
  }

  Future<void> login() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isLoggedIn = true;
      _userImageUrl = user.photoURL;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userImageUrl', _userImageUrl ?? '');
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userImageUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userImageUrl');
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
