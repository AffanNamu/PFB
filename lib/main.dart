import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfb/app.dart';
import 'package:pfb/services/fcm_service.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/local_notification_service.dart';
import 'package:pfb/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    if (!errorStr.contains('duplicate-app') &&
        !errorStr.contains('already exists')) {
      rethrow;
    }
  }
  try {
    await FcmService.instance.handleBackgroundMessage(message);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0B0B0B),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B0B0B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Object? startupError;
  StackTrace? startupStack;

  // ── Step 1: Initialize Firebase ──────────────────────────────────────────
  try {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 12));
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('duplicate-app') &&
          !errorStr.contains('already exists')) {
        rethrow;
      }
    }
  } catch (e, st) {
    startupError = Exception('Firebase init failed: $e');
    startupStack = st;
  }

  // ── Step 2 (Web only): Set persistence + consume redirect result ──────────
  //
  // This is the CORE of the Google Sign-In fix for Flutter Web.
  //
  // SEQUENCE OF EVENTS:
  //   A. User taps "Continue with Google" in LoginScreen / SignupScreen
  //   B. signInWithRedirect() fires → browser leaves the app
  //   C. Google OAuth completes → browser redirects to:
  //        https://phlakesfabric.web.app/__/auth/handler
  //      (now valid because we added it in Google Cloud Console)
  //   D. Firebase.__/auth/handler stores the credential and redirects
  //      browser back to the app's main URL:
  //        https://phlakesfabric.web.app
  //   E. Flutter app cold-boots again → main() runs
  //   F. getRedirectResultIfAny() reads the credential from IndexedDB
  //      (same origin = same IndexedDB = credential available)
  //   G. FirebaseAuth.currentUser is now set
  //   H. runApp() fires → SplashScreen reads currentUser → routes correctly
  if (startupError == null && kIsWeb) {
    // Set LOCAL persistence so auth survives tab closes
    try {
      await FirebaseAuth.instance
          .setPersistence(Persistence.LOCAL);
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | Web persistence → LOCAL');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | setPersistence error (non-fatal): $e');
      }
    }

    // Consume the redirect credential BEFORE runApp()
    try {
      final authService = FirebaseAuthService();
      final redirectUser =
          await authService.getRedirectResultIfAny();

      if (redirectUser != null) {
        if (kDebugMode) {
          debugPrint(
              '🔐 main() | ✅ Redirect sign-in resolved → '
              'uid=${redirectUser.uid}');
        }
        // User is now signed in. SplashScreen will read
        // FirebaseAuth.instance.currentUser correctly.
      }
    } catch (e) {
      // AuthFailure means a real sign-in error (e.g. account conflict).
      // We surface it after runApp via SplashScreen error state.
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | getRedirectResult error: $e');
      }
    }

    // Wait for Firebase to finish restoring auth state from IndexedDB.
    // authStateChanges always emits null first (loading), then the
    // real user. Waiting here means SplashScreen always sees the
    // correct currentUser on first render — no more "logged out" flash.
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
                '🔐 main() | authStateChanges timeout → guest');
          }
          return null;
        },
      );

      if (kDebugMode) {
        final u = FirebaseAuth.instance.currentUser;
        debugPrint(
            '🔐 main() | Auth state ready → '
            '${u != null ? 'uid=${u.uid}' : 'guest'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '🔐 main() | authStateChanges error: $e');
      }
    }
  }

  // ── Step 3: FCM background handler (non-web) ─────────────────────────────
  if (startupError == null && !kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (e, st) {
      startupError =
          Exception('FCM background registration failed: $e');
      startupStack = st;
    }
  }

  // ── Step 4: Local notifications (non-web) ───────────────────────────────
  if (startupError == null && !kIsWeb) {
    try {
      await LocalNotificationService.instance
          .initialize()
          .timeout(const Duration(seconds: 8));
    } catch (e, st) {
      startupError =
          Exception('Local notification init failed: $e');
      startupStack = st;
    }
  }

  // ── Step 5: Launch ───────────────────────────────────────────────────────
  runApp(
    startupError == null
        ? const IftApp()
        : StartupErrorApp(
            error: startupError!,
            stackTrace: startupStack,
          ),
  );

  if (startupError == null && !kIsWeb) {
    unawaited(_initializeFcmNonBlocking());
  }
  if (startupError == null && kIsWeb) {
    unawaited(_initializeFcmWebNonBlocking());
  }
}

Future<void> _initializeFcmNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {}
}

Future<void> _initializeFcmWebNonBlocking() async {
  try {
    await FcmService.instance
        .initialize()
        .timeout(const Duration(seconds: 20));
  } catch (_) {}
}

// ── Startup Error Screen ──────────────────────────────────────────────────────

class StartupErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const StartupErrorApp({
    super.key,
    required this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFD4AF37),
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App failed to start',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      '$error',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}