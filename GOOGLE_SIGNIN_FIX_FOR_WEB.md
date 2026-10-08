# Google Sign-In Fix — Sakash Web App
## Status: ✅ WORKING
## Date: 2025

---

## Problem Description

When an unauthenticated user clicked "Sign Up" or "Sign In" with Google on
the web app (phlakesfabric.web.app), the following sequence occurred:

1. Browser showed Google account selector ✅
2. User selected their Gmail and confirmed ✅
3. App returned to login/profile page as if NOT signed in ❌
4. Manual refresh → user was suddenly logged in (ghost success) ❌

---

## Root Cause

The OAuth redirect was going through:
  https://phlakesfabric.firebaseapp.com/__/auth/handler

But the app was served from:
  https://phlakesfabric.web.app

These are TWO DIFFERENT ORIGINS. The browser's same-origin policy
blocked Firebase from reading the OAuth credential stored in
sessionStorage at firebaseapp.com when the app reloaded at web.app.

The credential existed but was inaccessible — making sign-in appear
to fail even though it had technically succeeded at the OAuth level.

---

## The Fix (3 Parts — ALL required together)

### Part 1: Google Cloud Console
### Part 2: firebase_options.dart
### Part 3: main.dart

---

## Part 1: Google Cloud Console Changes

URL: https://console.cloud.google.com/apis/credentials?project=phlakesfabric

Steps taken:
1. Opened "Web client (auto created by Google Service)"
2. Under "Authorized JavaScript origins" — ADDED:
     https://phlakesfabric.web.app
   (kept existing: https://phlakesfabric.firebaseapp.com)

3. Under "Authorized redirect URIs" — ADDED:
     https://phlakesfabric.web.app/__/auth/handler
   (kept existing: https://phlakesfabric.firebaseapp.com/__/auth/handler)

4. Clicked SAVE
5. Waited 5 minutes for Google OAuth servers to propagate

### Firebase Console Changes

URL: Firebase Console → Authentication → Settings → Authorized domains

Confirmed both domains are listed:
  - phlakesfabric.firebaseapp.com  (default)
  - phlakesfabric.web.app          (added)

---

## Part 2: lib/firebase_options.dart

CRITICAL CHANGE: authDomain changed from firebaseapp.com to web.app

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:web::2a98e9d43bf45e964a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    authDomain:        'phlakesfabric.web.app',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyC-wnlmBUr8c1kny07uB5jGqdwGq5-GIDc',
    appId:             '1:1089917254734:android:d791dca74fb3e77e4a571f',
    messagingSenderId: '1089917254734',
    projectId:         'phlakesfabric',
    storageBucket:     'phlakesfabric.firebasestorage.app',
  );
}
```

---

## Part 3: lib/main.dart

CRITICAL CHANGE: Added getRedirectResult() call BEFORE runApp()
and added setPersistence(LOCAL) + authStateChanges().first wait.

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfb/app.dart';
import 'package:pfb/services/fcm_service.dart';
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

  // ── Step 2 (Web only): getRedirectResult + persistence + auth wait ────────
  //
  // WHY THIS WORKS:
  //
  // With authDomain = phlakesfabric.web.app AND the web.app redirect URI
  // added to Google Cloud Console, the OAuth round-trip now looks like:
  //
  //   1. User taps "Continue with Google"
  //   2. signInWithRedirect() fires
  //      Firebase builds redirect URL using authDomain (web.app):
  //        https://phlakesfabric.web.app/__/auth/handler
  //   3. Browser goes to accounts.google.com
  //   4. User picks account → Google redirects to:
  //        https://phlakesfabric.web.app/__/auth/handler
  //      (Google allows this because we added it to OAuth redirect URIs)
  //   5. Firebase handler at web.app stores credential in sessionStorage
  //      (same origin as the app = sessionStorage accessible)
  //   6. Browser returns to phlakesfabric.web.app
  //   7. Flutter app boots → main() calls getRedirectResult()
  //   8. Firebase reads credential from sessionStorage (SAME origin ✅)
  //   9. User is signed in BEFORE runApp() fires
  //  10. SplashScreen reads currentUser → routes correctly ✅
  if (startupError == null && kIsWeb) {
    // Keep user logged in across tab closes and browser restarts
    try {
      await FirebaseAuth.instance
          .setPersistence(Persistence.LOCAL);
      if (kDebugMode) {
        debugPrint('🔐 main() | Web persistence set to LOCAL');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 main() | setPersistence (non-fatal): $e');
      }
    }

    // Consume the pending redirect credential BEFORE runApp()
    // This is the core fix — without this call the credential
    // stored in sessionStorage is never read and sign-in appears
    // to fail even though OAuth completed successfully.
    try {
      final result =
          await FirebaseAuth.instance.getRedirectResult();

      if (result.user != null) {
        if (kDebugMode) {
          debugPrint(
            '🔐 main() | ✅ Redirect sign-in resolved → '
            'uid=${result.user!.uid} '
            'email=${result.user!.email}',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '🔐 main() | No pending redirect (normal cold start)',
          );
        }
      }
    } catch (e) {
      // no-auth-event fires on every normal cold start — not an error
      if (kDebugMode) {
        debugPrint('🔐 main() | getRedirectResult info: $e');
      }
    }

    // Wait for Firebase to fully restore auth state from IndexedDB
    // before runApp(). Without this wait, currentUser is null on
    // first render even for users who were previously logged in.
    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              '🔐 main() | authStateChanges timeout → guest',
            );
          }
          return null;
        },
      );

      if (kDebugMode) {
        debugPrint(
          '🔐 main() | Auth state ready → '
          '${user != null ? 'uid=${user.uid}' : 'guest'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 main() | authStateChanges (non-fatal): $e');
      }
    }
  }

  // ── Step 3: FCM background handler (non-web only) ────────────────────────
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

  // ── Step 4: Local notifications (non-web only) ───────────────────────────
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

  // ── Step 5: Launch the app ───────────────────────────────────────────────
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
```

---

## Files That Were NOT Changed

- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/signup_screen.dart
- lib/features/splash/presentation/screens/splash_screen.dart
- lib/core/routing/app_router.dart
- lib/services/firebase_auth_service.dart

---

## Deployment Commands

```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Verification Checklist

| Item                                              | Status |
|---------------------------------------------------|--------|
| phlakesfabric.web.app in Firebase Authorized Domains    | ✅ |
| phlakesfabric.firebaseapp.com in Firebase Authorized Domains | ✅ |
| https://phlakesfabric.web.app added to GCloud JS Origins | ✅ |
| https://phlakesfabric.web.app/__/auth/handler added to GCloud Redirect URIs | ✅ |
| authDomain set to phlakesfabric.web.app in firebase_options.dart | ✅ |
| getRedirectResult() called before runApp() in main.dart | ✅ |
| setPersistence(LOCAL) called before runApp() in main.dart | ✅ |
| authStateChanges().first awaited before runApp() in main.dart | ✅ |

---

## Why Each Piece Was Required

| Fix | Why |
|-----|-----|
| authDomain = web.app | Firebase builds the redirect URL using authDomain. Must match app origin |
| GCloud redirect URI = web.app/__/auth/handler | Google must be allowed to redirect to web.app. Without this = Error 400 |
| GCloud JS origin = web.app | Required for browser-based OAuth requests from web.app |
| getRedirectResult() before runApp() | Consumes the OAuth credential from sessionStorage before app renders |
| setPersistence(LOCAL) | Keeps user logged in across tab closes and phone sleep cycles |
| authStateChanges().first | Waits for Firebase to restore previously signed-in user from IndexedDB |

---

## Summary

The fix required changes at THREE levels simultaneously:

1. GOOGLE CLOUD CONSOLE — Register web.app as a valid OAuth origin and redirect URI
2. FIREBASE OPTIONS    — Set authDomain to web.app so redirect URLs match
3. MAIN.DART          — Consume redirect result before app renders
4. check login and signup screen too
All three were required. Any one missing caused the sign-in to fail.

