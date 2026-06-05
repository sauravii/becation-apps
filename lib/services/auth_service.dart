import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Auth-flow service: bungkus FirebaseAuth + GoogleSignIn.
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  static String? get currentDisplayName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  static Future<User?> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  // Kirim link reset password ke email. Throws [AuthException].
  static Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }


  static Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      // Clear cached account dulu supaya picker selalu muncul.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return GoogleAuthResult(cancelled: true);
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return GoogleAuthResult(
        user: userCred.user,
        isNewUser: userCred.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  // Sign out dari FirebaseAuth + GoogleSignIn (clear cached Google account).
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      debugPrint('[AuthService] google signOut failed: $e\n$st');
    }
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> deleteCurrentUser() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e, st) {
      debugPrint('[AuthService] delete current user failed: $e\n$st');
    }
  }
}

// Hasil Google Sign-In. [cancelled] true kalau user nutup dialog tanpa pilih akun.
class GoogleAuthResult {
  final User? user;
  final bool isNewUser;
  final bool cancelled;

  GoogleAuthResult({
    this.user,
    this.isNewUser = false,
    this.cancelled = false,
  });
}

// Error auth yang sudah dinormalisasi — page map [code] ke pesan UI English.
class AuthException implements Exception {
  final String code;
  final String? message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}
