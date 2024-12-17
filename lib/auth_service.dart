import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Stream of authentication state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Phone Number Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // Verify SMS Code and Sign In
  Future<User?> signInWithPhoneNumber(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Log first-time login or signup event
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await _analytics.logSignUp(signUpMethod: 'phone');
        await _sendWelcomeNotification('phone');
      } else {
        await _analytics.logLogin(loginMethod: 'phone');
      }
      
      return result.user;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // Email and Password Sign Up
  Future<User?> signUp({
    required String email, 
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
      }

      // Log sign-up event
      await _analytics.logSignUp(signUpMethod: 'email');
      await _sendWelcomeNotification('email');

      return result.user;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // Email and Password Sign In
  Future<User?> signIn({
    required String email, 
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log login event
      await _analytics.logLogin(loginMethod: 'email');
      
      return result.user;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Log first-time login or regular login
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await _analytics.logSignUp(signUpMethod: 'google');
        await _sendWelcomeNotification('google');
      } else {
        await _analytics.logLogin(loginMethod: 'google');
      }
      
      return result.user;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log password reset event
      await _analytics.logEvent(
        name: 'password_reset_requested',
        parameters: {'email': email},
      );
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // Send Welcome Notification
  Future<void> _sendWelcomeNotification(String method) async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        
        // Log new user token
        await _analytics.logEvent(
          name: 'new_user_welcome',
          parameters: {
            'method': method,
            'token': token ?? 'unknown',
          },
        );

        // Optional: Send a direct notification (might require backend setup)
        // This is a placeholder and may need additional backend configuration
        if (kDebugMode) {
          print('Welcome notification for $method login');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending welcome notification: $e');
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // Log sign out event
      await _analytics.logEvent(name: 'sign_out');
    } catch (e) {
      _handleAuthError(e);
    }
  }

  // Error Handling
  void _handleAuthError(dynamic error) {
    if (kDebugMode) {
      print('Authentication Error: $error');
    }

    // Log error to analytics
    _analytics.logEvent(
      name: 'auth_error',
      parameters: {'error': error.toString()},
    );

    // Optional: You can add more specific error handling here
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          // Handle user not found
          break;
        case 'wrong-password':
          // Handle incorrect password
          break;
        case 'email-already-in-use':
          // Handle email already in use
          break;
        // Add more specific error codes as needed
      }
    }
  }

  // Check Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Reload User
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _handleAuthError(e);
    }
  }
}