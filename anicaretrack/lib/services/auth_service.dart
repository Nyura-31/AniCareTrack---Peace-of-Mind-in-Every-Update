import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Email already in use.";
      } else if (e.code == 'weak-password') {
        return "Password is too weak.";
      } else {
        return "Something went wrong.";
      }
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        return "Wrong password.";
      } else {
        return "Invalid credentials.";
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}