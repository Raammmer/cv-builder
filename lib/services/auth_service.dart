import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Authentication.
/// Supports Email/Password and Google Sign-In (OAuth).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- Email & Password ---

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Web Client ID from Firebase Authentication for project cv-builder-64e52.
  static const String serverClientId =
      '773541196171-g86e1o55m0306446dnnhsddd1ml93q7o.apps.googleusercontent.com';

  /// Returns false if the user cancelled the Google account picker.
  Future<bool> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(
        serverClientId: serverClientId,
      );
      _googleInitialized = true;
    }

    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google did not return an ID token. Ensure SHA-1 fingerprint and updated google-services.json are configured.',
        );
      }
      await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return false;
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleInitialized) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Converts Firebase / Google errors into short, friendly messages.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Try signing in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and try again.';
        case 'account-exists-with-different-credential':
          return 'This email is already linked to a different sign-in method.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase Console. Go to Authentication > Sign-in method and enable it.';
        default:
          return error.message ?? 'Authentication failed (${error.code}).';
      }
    }
    if (error is GoogleSignInException) {
      return 'Google sign-in failed (${error.code.name}): ${error.description ?? "Check Firebase console & SHA-1."}';
    }
    if (error is PlatformException) {
      final msg = error.message ?? '';
      if (msg.contains('10:') || msg.contains('ApiException: 10')) {
        return 'Google Sign-In error (ApiException 10): SHA-1 fingerprint or package name mismatch. Check Firebase console for com.example.cv_builder.';
      }
      return 'Sign-in error: ${error.message ?? error.code}';
    }
    final rawMsg = error.toString();
    if (rawMsg.contains('ApiException: 10') || rawMsg.contains('10:')) {
      return 'Google Sign-In error (ApiException 10): SHA-1 fingerprint or package name mismatch. Check Firebase console.';
    }
    return 'Authentication error: $rawMsg';
  }
}
