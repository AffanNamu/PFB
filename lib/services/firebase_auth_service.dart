import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pfb/services/fcm_service.dart';

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId:
                  '1089917254734-tfkid7lmbe20tr9p6u459bvil8qssm7v.apps.googleusercontent.com',
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // ── Called in main() before runApp() on web ──────────────────────────────
  // Now that the Google Cloud Console has the web.app redirect URI,
  // getRedirectResult() will successfully read the credential that
  // Firebase stored during the OAuth round-trip.
  Future<User?> getRedirectResultIfAny() async {
    if (!kIsWeb) return null;
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | Checking redirect result…');
      }

      final result = await _firebaseAuth
          .getRedirectResult()
          .timeout(const Duration(seconds: 15));

      final user = result.user;

      if (user != null) {
        if (kDebugMode) {
          debugPrint(
              '🔐 Sakash | ✅ Redirect sign-in resolved → '
              'uid=${user.uid} email=${user.email}');
        }
        try {
          await FcmService.instance.syncTokenForCurrentUser();
        } catch (_) {}
        return user;
      }

      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | No pending redirect '
            '(normal cold start)');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | getRedirectResult '
            'FirebaseAuthException: code=${e.code}');
      }
      // no-auth-event = no redirect pending, totally normal
      if (e.code == 'no-auth-event' ||
          e.code == 'null-user') {
        return null;
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | getRedirectResult unknown: $e');
      }
      return null;
    }
  }

  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Sign in failed. Please try again.');
    }
  }

  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FcmService.instance.syncTokenForCurrentUser();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Account creation failed. Please try again.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  //
  // WEB: signInWithRedirect
  //   Now that the Google Cloud Console has been updated to allow
  //   https://phlakesfabric.web.app/__/auth/handler as a redirect URI,
  //   the redirect will return to web.app (same origin as the app).
  //   getRedirectResultIfAny() in main() will then successfully consume
  //   the credential before the app renders anything.
  //
  // ANDROID: google_sign_in package + credential exchange
  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | Google Sign-In start '
            '(kIsWeb=$kIsWeb)');
      }

      if (kIsWeb) {
        return await _googleSignInWeb();
      }

      return await _googleSignInAndroid();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | FirebaseAuthException: '
            'code=${e.code} message=${e.message}');
      }
      throw AuthFailure(_mapFirebaseError(e.code, e.message));
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 Sakash | PlatformException: '
            'code=${e.code} message=${e.message}');
      }
      throw AuthFailure(_mapGooglePlatformError(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      if (kDebugMode) {
        debugPrint('🔐 Sakash | Unknown: $e');
      }
      throw AuthFailure(
          'Google Sign-In failed. Please try again.');
    }
  }

  // ── Web: redirect flow ────────────────────────────────────────────────────
  Future<User?> _googleSignInWeb() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    provider.addScope('email');
    provider.addScope('profile');

    if (kDebugMode) {
      debugPrint(
          '🔐 Sakash | Web: calling signInWithRedirect…\n'
          '  authDomain will handle redirect at:\n'
          '  https://phlakesfabric.web.app/__/auth/handler');
    }

    // Browser navigates away here. Returns null — the result is
    // consumed by getRedirectResultIfAny() called in main() on
    // the next page load BEFORE runApp() is called.
    await _firebaseAuth.signInWithRedirect(provider);

    // Never reached in the same page lifecycle.
    return null;
  }

  // ── Android: native flow ─────────────────────────────────────────────────
  Future<User?> _googleSignInAndroid() async {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      throw AuthFailure('Google sign-in was cancelled.');
    }

    if (kDebugMode) {
      debugPrint(
          '🔐 Sakash | Android: account selected '
          '${googleUser.email}');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if ((googleAuth.idToken ?? '').isEmpty) {
      throw AuthFailure(
        'Google sign-in failed: no ID token returned. '
        'Verify SHA-1 fingerprint in Firebase Console '
        'for com.pfb.app',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw AuthFailure(
          'Google sign-in failed. Please try again.');
    }

    await FcmService.instance.syncTokenForCurrentUser();

    if (kDebugMode) {
      debugPrint(
          '🔐 Sakash | Android success uid=${user.uid}');
    }

    return user;
  }

  Future<void> signOut() async {
    try {
      await FcmService.instance
          .removeCurrentDeviceTokenForCurrentUser();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    await _firebaseAuth.signOut();

    if (kDebugMode) {
      debugPrint('🔐 Sakash | Signed out');
    }
  }

  String _mapGooglePlatformError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    final combined = '$code $message $details';

    if (combined.contains('10') ||
        combined.contains('developer_error') ||
        combined.contains('sign_in_failed')) {
      return 'Google Sign-In configuration error. '
          'Verify SHA-1 fingerprint in Firebase Console.';
    }
    if (combined.contains('network_error')) {
      return 'Network error. Please check your internet.';
    }
    if (combined.contains('sign_in_canceled') ||
        combined.contains('canceled') ||
        combined.contains('cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (combined.contains('12500')) {
      return 'OAuth error. Verify SHA fingerprints.';
    }
    if (combined.contains('12501')) {
      return 'Google sign-in was cancelled.';
    }
    if (combined.contains('12502')) {
      return 'Google sign-in in progress. Please wait.';
    }
    return 'Google Sign-In failed: ${e.message}';
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'This email uses a different sign-in method.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Contact support.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'popup-blocked':
        return 'Pop-up blocked. Allow pop-ups and try again.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }
}