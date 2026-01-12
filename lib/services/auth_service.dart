import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_strings.dart';

/// Authentication service
/// Supports Google, Apple, and Email/Password authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService() {
    _auth.setLanguageCode('tr'); // Set locale to Turkish to fix warning and localized emails
  }
  
  // Rate limiting for verification emails
  DateTime? _lastVerificationSent;
  static const _verificationCooldown = Duration(seconds: 60);

  // ==================== GETTERS ====================

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Is email verified?
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
  
  /// Seconds until next verification email can be sent
  int get verificationCooldownSeconds {
    if (_lastVerificationSent == null) return 0;
    final elapsed = DateTime.now().difference(_lastVerificationSent!);
    final remaining = _verificationCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }
  
  /// Can send verification email now?
  bool get canSendVerificationEmail => verificationCooldownSeconds == 0;

  // ==================== GOOGLE SIGN-IN ====================

  /// Sign in with Google (OAuth - passwordless)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE SIGN IN AUTH ERROR: ${e.code} - ${e.message}');
      
      if (e.code == 'invalid-credential') {
        debugPrint('Stale Google token detected. Attempting auto-retry with disconnect...');
        try {
           // Disconnect first to ensure we can clear the cache before signing out locally
           try { await _googleSignIn.disconnect(); } catch (_) {}
           await _googleSignIn.signOut();
           await _auth.signOut();
        } catch (_) {}
        
        try {
          // Retry once
          final GoogleSignInAccount? retryUser = await _googleSignIn.signIn();
          if (retryUser == null) return null;
          
          final GoogleSignInAuthentication retryAuth = await retryUser.authentication;
          final retryCredential = GoogleAuthProvider.credential(
            accessToken: retryAuth.accessToken,
            idToken: retryAuth.idToken,
          );
          return await _auth.signInWithCredential(retryCredential);
        } catch (retryE) {
          debugPrint('Retry failed: $retryE');
          // Fallback message if even disconnect fails
          throw 'Oturum yenilenemedi. Lütfen tekrar deneyin.';
        }
      }
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('GOOGLE SIGN IN UNKNOWN ERROR: $e');
      throw AppStrings.authErrorGeneric;
    }
  }

  // ==================== APPLE SIGN-IN ====================

  /// Sign in with Apple (OAuth - passwordless, iOS/macOS only)
  Future<UserCredential?> signInWithApple() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw AppStrings.authErrorOperationNotAllowed;
      }

      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      return await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw AppStrings.authErrorGeneric;
    }
  }

  // ==================== EMAIL/PASSWORD ====================

  /// Register with email and password
  /// After registration, user is signed out and must verify email before logging in
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName.trim());

      // Send email verification
      await credential.user?.sendEmailVerification();
      _lastVerificationSent = DateTime.now();

      // Sign out immediately - user must verify email first
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw AppStrings.authErrorGeneric;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Check email verification
      if (credential.user != null && !credential.user!.emailVerified) {
        // Sign out unverified user
        await _auth.signOut();
        throw AppStrings.emailVerificationRequired;
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw AppStrings.authErrorGeneric;
    }
  }

  /// Resend email verification link with rate limiting
  Future<bool> resendEmailVerification() async {
    try {
      // Check cooldown
      if (!canSendVerificationEmail) {
        return false;
      }
      
      // Need to temporarily sign in to send verification
      await currentUser?.sendEmailVerification();
      _lastVerificationSent = DateTime.now();
      return true;
    } catch (e) {
      throw AppStrings.authErrorGeneric;
    }
  }
  
  /// Send verification to a specific email (for registration flow)
  Future<bool> sendVerificationToEmail(String email, String password) async {
    try {
      if (!canSendVerificationEmail) {
        return false;
      }
      
      // Temporarily sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Send verification
      await credential.user?.sendEmailVerification();
      _lastVerificationSent = DateTime.now();
      
      // Sign out again
      await _auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw AppStrings.authErrorGeneric;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AppStrings.authErrorGeneric;
    }
  }
  
  /// Reload user to check email verification status
  Future<bool> checkEmailVerified() async {
    try {
      await currentUser?.reload();
      return currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Force Google disconnect to revoke token permissions
      try {
        if (await _googleSignIn.isSignedIn()) {
           await _googleSignIn.disconnect();
        }
      } catch (e) {
        debugPrint('Google disconnect error (ignored): $e');
      }
      
      // Then sign out locally
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw AppStrings.authErrorGeneric;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Convert Firebase Auth exceptions to localized user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Account issues
      case 'account-exists-with-different-credential':
      case 'email-already-in-use':
        return AppStrings.authErrorEmailInUse;
      case 'user-disabled':
        return AppStrings.authErrorAccountDisabled;
      case 'user-not-found':
        return AppStrings.authErrorUserNotFound;
      
      // Credential issues
      case 'invalid-credential':
        return AppStrings.authErrorInvalidCredential;
      case 'wrong-password':
        return AppStrings.authErrorWrongPassword;
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      case 'weak-password':
        return AppStrings.authErrorWeakPassword;
      
      // Rate limiting
      case 'too-many-requests':
        return AppStrings.authErrorTooManyRequests;
      
      // Operation issues
      case 'operation-not-allowed':
        return AppStrings.authErrorOperationNotAllowed;
      
      // Network
      case 'network-request-failed':
        return AppStrings.authErrorNetwork;
      
      default:
        return AppStrings.authErrorGeneric;
    }
  }
}
