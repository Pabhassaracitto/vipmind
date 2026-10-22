import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Single place that touches Firebase.
///
/// Every accessor is **null-safe**: reading `FirebaseAuth.instance` or
/// `FirebaseFirestore.instance` throws when Firebase has not been initialised
/// (missing `google-services.json` processing on Android, missing
/// `GoogleService-Info.plist` on iOS). Several screens used to read
/// `FirebaseAuth.instance.currentUser` directly inside `build()`/`initState()`,
/// which took the whole screen down instead of showing a signed-out UI.
///
/// Rule: UI code reads [currentUser] / [currentUserId] / [isReady] from here
/// and never touches `FirebaseAuth.instance` itself.
class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// `true` once `Firebase.initializeApp()` succeeded (see `lib/main.dart`).
  static bool get isReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Current User — never throws.
  static User? get currentUser {
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get currentUserId => currentUser?.uid;
  static bool get isLoggedIn => currentUser != null;

  /// Signs out; returns `false` (instead of throwing) when Firebase is absent.
  static Future<bool> trySignOut() async {
    try {
      await auth.signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

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
  static CollectionReference<Map<String, dynamic>> userMindmaps(
          String userId) =>
      firestore.collection('users').doc(userId).collection('mindmaps');
}
