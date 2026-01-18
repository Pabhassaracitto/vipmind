import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Current User
  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => auth.currentUser?.uid;
  static bool get isLoggedIn => auth.currentUser != null;

  // Auth State Stream
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign In
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  // Update Display Name
  static Future<void> updateDisplayName(String name) async {
    await auth.currentUser?.updateDisplayName(name);
  }

  // Firestore Collections
  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get mindmapsCollection =>
      firestore.collection('mindmaps');

  static CollectionReference<Map<String, dynamic>> get templatesCollection =>
      firestore.collection('templates');

  // Get user mindmaps collection
  static CollectionReference<Map<String, dynamic>> userMindmaps(String userId) =>
      firestore.collection('users').doc(userId).collection('mindmaps');
}