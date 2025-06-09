import 'package:firebase_auth/firebase_auth.dart';

class UserData {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserData({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserData.fromFirebaseUser(User user) {
    return UserData(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }
}
