# Sakash Collection — Technical & Product Documentation

> **Repository:** [AffanNamu/PFB](https://github.com/AffanNamu/PFB)  
> **Default branch reviewed:** `main`  
> **Application package:** `pfb`  
> **Flutter app version declared in pubspec:** `1.2.0+1`  
> **Android application ID:** `com.pfb.app`  
> **Documentation scope:** Architecture, feature map, data flows, setup, deployment, operations, and known implementation/security caveats.

---

## 1. Overview

Sakash Collection is a Flutter application for textile/fabric commerce and the operational workflow around customer orders and deliveries. The repository also contains an employee-facing point-of-sale (POS) terminal and administrative tooling.

The app is built for multiple surfaces: Android and Flutter Web are configured in the repository, and the Flutter dependencies include iOS-capable plugins, although a complete iOS release setup was not validated during this review.

The implementation combines:
- Product discovery, product details, fabric-specific product attributes, favorites, and a shopping cart.
- Customer accounts and Google/Firebase authentication.
- Checkout and Paystack transaction initialization.
- Order history, status updates, and delivery tracking/map screens.
- Admin product, order, delivery/ride, coverage, and payment settings.
- Location-aware admin assignment, workload limits, super-admin escalation, and manual reassignment.
- POS checkout, discounts, payment methods, receipts, and POS analytics.
- Super-admin reporting and operational analytics.
- Firebase Cloud Messaging (FCM), local notifications, and navigation from notification taps.

This document distinguishes **observed implementation** from **operational recommendations**. It is not a security audit or proof that a configured deployment is working.

## 2. Product capabilities

### 2.1 Customer commerce

The customer-facing experience includes:
- Account registration and login.
- Product catalogue, search/filtering, product details, and fabric attributes.
- Product images and promotional information.
- Favorites and cart quantity management.
- Delivery-address selection and address lookup/geocoding support.
- Checkout settings such as delivery fee, coupon discount, minimum order and free-delivery threshold.
- Paystack checkout handoff.
- Order history and status information.
- Notifications and profile management.

The product model is designed for textiles, with fields including fabric type, material, colors, sizes, yardage, GSM, care instructions, occasion, gender, origin, new-arrival/bestseller flags, ratings, and review counts.

### 2.2 Administration

The admin feature area contains screens for:
- Main dashboard and order operations.
- Adding, editing, and managing products.
- Categories.
- Admin coverage locations and workload configuration.
- Ride/delivery operational screens.
- Payment settings.
- Escalation handling and reassignment.
- Super-admin analytics.

Admin role labels in the code include **cashier**, **store manager**, **admin**, and **super admin**. The role enum exposes capabilities such as POS access and product management. Actual authorization must also be enforced by Firestore Security Rules or trusted backend checks; client-side navigation/role checks alone are not a security boundary.

### 2.3 Point of sale (POS)

The POS module contains a dedicated dashboard, checkout screen, cart/search widgets, discount and payment sheets, receipt preview, and receipt screen.

The repository defines POS models and Firestore collections for:
- `pos_sales`
- `pos_receipts`
- `pos_analytics`
- `admin_performance`

The repository includes:
- Receipt ID generation in the form `PFB-YYYYMMDD-NNNN`.
- Product reuse from the shared product stream.
- Client-side searching by product name, category, and fabric type.
- Subtotal, percentage/fixed discount, final-total, and cash-change calculations.
- Persistence/analytics integration through `PosRepository` and `PosAnalyticsBridge`.

The receipt identifier includes a random four-digit suffix; do not treat it as a globally collision-proof identifier without an additional uniqueness check or database constraint.

### 2.4 Orders, delivery and admin assignment

Order records contain commerce fields such as item lines, subtotal/total, delivery fee, coupon details, payment reference/status, notes, tracking information, status, and destination address. They also contain assignment metadata such as assigned admin identity, distance, state/area, assignment method, active-load snapshot, and whether the item was escalated to the super admin.

The current assignment strategy examines admin coverage area names, coverage states, service radius and current workload/capacity. Admin records can include:
- `baseAddress`, `baseLat`, `baseLng`
- `serviceRadiusKm`
- `coverageStates`, `coverageAreas`
- `isActive`
- `maxActiveAssignments`

If a suitable local admin cannot be selected, the code includes a super-admin fallback path. A super admin can also reassign an order manually. These mechanisms are intended to preserve operational ownership when coverage is incomplete or an admin is overloaded.

**Implementation note:** the inspected `placeOrder` path calls `findNearestAdmin` with fixed Nigeria-centre coordinates (`9.0820, 8.6753`) while supplying the resolved destination address. Treat this as a material location-assignment limitation: the score/radius calculation may not reflect the customer's true delivery coordinates. Confirm and correct this before relying on geographic distance assignment in production.

### 2.5 Notifications

The notification implementation has client-side FCM token management, foreground/background message handling, local notification display and tap navigation. Device tokens are written to user records and, where a corresponding admin record exists, admin records too.

The repository contains Supabase Edge Functions:
- `send-fcm-notification`: obtains a Google OAuth access token using Firebase service-account secrets and sends FCM HTTP v1 messages.
- `init-paystack-transaction`: validates a shared function secret and initializes a Paystack transaction with a backend-only Paystack secret.

Existing repository notes describe notifications wired into order creation, status changes, reassignment and escalation. The current notes also acknowledge that event triggers are initiated by app-side service logic rather than a durable backend event queue.

### 2.6 Analytics

The super-admin analytics screen supports date windows (today, last 7 days, last 30 days, all time, and a custom range in the current code) and filters for state, admin and area. It combines online order information with POS analytics through the POS analytics bridge. Reported metrics include sales, order totals, admin performance, movement/delivery activity, escalation and reassignment metrics. Verify the exact calculation and filtering in the screen before using a metric for financial reporting.

## 3. Technology stack

| Layer | Technology observed in repository | Responsibility |
|---|---|---|
| Client application | Flutter / Dart | Android and Web UI; shared feature implementation |
| Authentication | Firebase Authentication | User sessions and Google sign-in |
| Primary operational data | Cloud Firestore | Products, users, admins, orders, settings, payment attempts and POS records |
| Push messaging | Firebase Cloud Messaging | Remote push delivery |
| Local notifications | `flutter_local_notifications` | Presenting notifications while app is active/background handling |
| Payment initialization | Supabase Edge Functions + Paystack API | Server-side transaction initialization |
| Notification sender | Supabase Edge Functions + FCM HTTP v1 | Server-side push message requests |
| Maps / location | `flutter_map`, `latlong2`, `geolocator`, app geocoding/routing services | Map display, coordinates, location and route support |
| Product media | Cloudinary service wrapper | Media upload/integration |
| Web hosting | Firebase Hosting workflow | Deploying the compiled Flutter Web app |
| CI/CD | GitHub Actions | Automated Web build/deploy and Android-related workflows |
| Receipts | `pdf`, `printing`, `gal`, `share_plus` | Receipt generation, printing/export, saving and sharing |

The Flutter package manifest sets the Dart SDK range to `>=3.2.0 <4.0.0`. It declares Firebase Core/Auth/Messaging/Firestore, Google Sign-In, Google Fonts, image/file pickers, HTTP, shared preferences, URL launcher, permission handling, map/location packages, PDF/printing and receipt-sharing packages.

## 4. Architecture and code organization

The project uses a feature-oriented structure with shared services and domain models.

```text
lib/
  main.dart                      App bootstrap and platform initialization
  app.dart                       MaterialApp, theme, navigation setup
  bootstrap.dart                 Bootstrap helper
  firebase_options.dart          FlutterFire platform configuration
  config/routes/                 Route names and route configuration
  core/
    constants/                   App constants, URLs, colors, theme constants
    routing/                     AppRouter and navigation helpers
    theme/                       Theme system and theme state
  features/
    auth/                        Login and signup
    products/                    Catalogue and product details
    cart/                        Cart and payment verification screens
    favorites/                   Favorites
    orders/                      Order history and detail
    rider/                       Order/delivery tracking and maps
    notifications/               Notification centre
    admin/                       Admin and super-admin operations
    pos/                         POS repository, models, checkout and receipts
    profile/                     Customer profile and address UI
    shell/                       Main app navigation shell
    shared/                      Shared feature widgets
    splash/                      Startup/auth routing experience
  models/                         Product, order, ride, payment and notification models
  services/                       Firebase, auth, payments, FCM, location, media services
  shared/widgets/                 Reusable app-wide UI components
  utils/                          Utility/validation modules

supabase/functions/
  init-paystack-transaction/      Paystack transaction initialization
  send-fcm-notification/          FCM HTTP v1 sender

.github/workflows/                Build/deployment automation
android/                          Native Android project configuration
web/                              Flutter Web shell and manifest
```

### 4.1 Application startup

`lib/main.dart`:
1. Ensures Flutter bindings are ready.
2. Applies Android-style system UI settings where applicable.
3. Initializes Firebase with generated platform options, with a timeout and an error fallback screen.
4. On Web, sets Firebase Auth persistence to local and consumes Google sign-in redirect results before launching the app.
5. Registers the FCM background message handler on non-Web platforms.
6. Initializes local notifications on non-Web platforms.
7. Launches `IftApp`, then initializes FCM non-blockingly.

`lib/app.dart` creates the app-level theme and admin-preview controllers, registers a navigator key for notification navigation, and connects `AppRouter.onGenerateRoute` to the Material application.

### 4.2 Navigation

Route names are centralized under `lib/config/routes/route_names.dart`, and named route construction is handled by `lib/core/routing/app_router.dart`. The router covers the customer shell, auth, cart, orders, profile, favorites, notifications, admin screens and POS receipts. POS receipt navigation accepts either a sale object or receipt ID and includes a fallback error screen for invalid arguments.

### 4.3 Data-access convention

Most business operations pass through `FirebaseService`, while POS operations are collected in `PosRepository`. UI screens subscribe to Firestore-backed streams for live product/order/admin data where implemented. Shared model classes convert Firestore maps to strongly typed app objects.

This is a pragmatic Flutter application architecture rather than a strict clean-architecture separation: some screens contain substantial UI and orchestration logic. New work should avoid duplicating Firestore behavior across screens and should prefer the existing service/repository entry points.

## 5. Main data model and Firestore collections

The source constants identify the following main collection names. Fields below are representative fields observed in model/service code, not a complete database schema.

| Collection | Purpose | Representative data |
|---|---|---|
| `products` | Product catalogue | Name, description, price, image URLs, categories, stock, textile attributes, rating/promotion flags |
| `users` | Customer profiles and device tokens | Display name, addresses, selected address, favourites/cart-related data, FCM tokens |
| `admins` | Admin identity and operation configuration | Email, role, location, coverage areas/states, active/capacity settings, FCM tokens |
| `orders` | Customer purchases and delivery operations | User, item list, totals, status, payment fields, delivery address, assignment fields |
| `rides` | Legacy movement records/compatibility | Ride/delivery details and older dispatch metadata |
| `categories` | Catalogue categories | Category records |
| `payments` | Successful/verified payment records | Payment reference, payer, amount, items and metadata |
| `payment_attempts` | Payment initialization lifecycle | Reference, amount, user, gateway URL, current attempt status and errors |
| `app_settings` | Runtime app settings | Vendor pickup address and payment/pricing settings as used by services |
| `pos_sales` | Completed POS sales | Line items, cashier, discounts, tender/payment details and totals |
| `pos_receipts` | POS receipt records | Receipt/sale linkage and receipt data |
| `pos_analytics` | Aggregated or queryable POS analytics | POS metrics consumed by the analytics bridge |
| `admin_performance` | Admin performance records | POS/admin performance metrics |

Notifications are stored in subcollections under user/admin documents (the service uses a `notifications` subcollection) in addition to FCM device-token data.

### 5.1 Order statuses and payment data

Order status is stored as a string. The UI/service messaging specifically handles statuses such as `processing`, `shipped`, `delivered`, and `cancelled`, with `pending` used when a new order is written. Keep status strings consistent across UI, analytics, notifications and operations.

Order payment fields include `paymentReference` and `paymentStatus`; the data model accepts optional coupon, discount, delivery fee, notes and tracking number. Legacy `deliveryRideId` and ride-related model code remain for compatibility during transition. A model comment says new movement writes have moved toward order records while the legacy ride model is retained for existing code/documents. Do not remove legacy fields/collections without migration and usage review.

## 6. Key business workflows

### 6.1 Product catalogue

1. Product screens request data through `FirebaseService`/the product repository.
2. Firestore product snapshots are mapped to `ProductModel`.
3. The catalogue UI applies searches, categories and product-specific filters.
4. Details use product fields and image URLs for presentation.
5. Admin workflows create/update/delete product records.

The product model normalizes multiple categories and offers computed values such as whether an item is discounted and its discounted price.

### 6.2 Cart and checkout

1. The customer adds product lines and adjusts quantities.
2. Cart data may be stored/synchronized through the Firebase service; local-cart support exists for continuity.
3. Checkout computes item subtotal and applies delivery/coupon values.
4. Payment settings are read from app configuration/runtime Firestore settings.
5. PaymentService creates a payment-attempt record and calls the Supabase initialization function.
6. The returned Paystack authorization URL is opened externally.
7. The user returns to the app, where a payment-return/verification UI continues the order flow.
8. The service persists the order and associated payment metadata.

**Critical payment limitation:** the inspected client service contains `confirmManualPaymentSuccess`, which marks an attempt successful and writes a verified payment record after the user returns. The deployment notes explicitly describe this as manual confirmation, not a fraud-proof server verification. Do not equate a client-reported return with Paystack-confirmed settlement. Before production payments are trusted, implement server-to-server verification (Paystack verify endpoint and/or a signed webhook), make the server the source of truth, and create/fulfil orders idempotently only after a verified successful transaction.

### 6.3 Admin assignment when an order is placed

1. The service resolves a delivery address.
2. It loads admin coverage configurations.
3. It first considers textual area matches, then state matches, then radius-based candidates.
4. Inactive admins, candidates lacking coordinates and admins over capacity are excluded.
5. A candidate is scored with factors including distance, coverage match and workload.
6. When no suitable local admin qualifies, the code includes super-admin fallback escalation.
7. The chosen admin and assignment rationale are stored on the order.
8. Notification helpers can alert the customer, assigned admin or super admin.
9. Super admin can manually reassign the order, updating its assignment metadata and notifying the receiving admin.

**Geospatial caveat:** the inspected order placement implementation currently supplies the centre of Nigeria as the target coordinates rather than the customer's actual geocoded destination coordinates. Address text may contribute to area/state selection, but this fixed coordinate makes geographic scoring unreliable. Fix this before using the result as a true nearest-admin guarantee.

### 6.4 POS sale

1. The cashier searches shared product data.
2. Items are added to the POS cart.
3. Subtotal and discounts are calculated.
4. Payment method and tender/amount are entered.
5. The sale is persisted through the POS repository.
6. Receipt data is presented; the app includes support packages for PDF/printing, saving receipt imagery, and sharing.
7. The analytics bridge feeds POS information into super-admin analytics.

Validate all monetary calculations at the trusted persistence boundary if prices, discounts or role permissions could be manipulated by a client.

### 6.5 Notification lifecycle

The client initializes FCM, requests permission, retrieves a token, writes it to the signed-in user's Firestore record and listens for token refreshes. Foreground messages can be converted to local notifications. Taps from opened/background/initial messages are passed to `NotificationNavigationService`.

The Supabase FCM function accepts tokens and notification metadata, creates a Google OAuth JWT assertion from configured service account values, obtains an access token and sends FCM HTTP v1 requests. Sending is sequential per unique token in the current implementation, so high-volume batches may be slow; a queue and bounded concurrency are reasonable future improvements.

## 7. Runtime configuration and secrets

### 7.1 Flutter/Firebase

The repository includes `lib/firebase_options.dart`, Android Firebase configuration, `firebase.json`, Firestore indexes, and Web app files. These must match the intended Firebase project and target platform.

Before development or deployment:
- Verify that Firebase project configuration points to the intended environment.
- Configure Firebase Authentication providers and authorized domains for Web Google sign-in.
- Apply and review Firestore Security Rules and required indexes.
- Configure FCM, Android notification channel/icon expectations, and platform-specific messaging capabilities.
- Ensure every required asset declared in `pubspec.yaml` exists in the build context.

### 7.2 Supabase Edge Function secrets

The function source expects these secrets:

For Paystack initialization:
- `MIX_FUNCTION_SECRET`: shared request-authentication value.
- `PAYSTACK_SECRET_KEY`: backend-only Paystack secret.

For FCM sending:
- `MIX_FUNCTION_SECRET`: shared request-authentication value.
- `FIREBASE_CLIENT_EMAIL`: Firebase service-account client email.
- `FIREBASE_PRIVATE_KEY`: Firebase service-account private key, with newlines represented correctly for the runtime.
- `FIREBASE_PROJECT_ID`: Firebase project ID.

Set these in Supabase's function secrets/environment. Do not commit production values to source control.

### 7.3 Important security remediation before production

A review of the current public source found configuration and key-management issues that should be treated as urgent:
- `AppConstants.supabaseFunctionSecret` is a placeholder value and is sent by the client as a Bearer secret. **A shared secret embedded in a Flutter client is not secret**—any user who extracts the app can reuse it. Replace this architecture with authenticated user JWT validation and authorization in Edge Functions, rate limiting, and server-side checks; do not solve it by embedding a stronger string.
- A Paystack public test key is present in app constants. Confirm the intended environment and replace it with the correct public key only where needed. Keep Paystack **secret** keys server-side.
- The repository tree also contains files with names such as `android/app/upload-keystore.jks`, `debug.keystore`, `keystore.base64`, `keystore_base64.txt`, `android/key.properties`, `gsj.txt`, and `android/app/google-services.json`. Their presence is a serious key/configuration hygiene concern. Review exactly what each contains, rotate any exposed credentials or signing materials as appropriate, and move private signing material to protected CI secrets or secure storage. Do not assume deleting a file from the latest commit removes it from Git history.
- Super-admin UIDs and an email comment are hard-coded in app constants. Client-side allowlists can help drive UI behaviour but must not be used as the only authorization barrier.
- The FCM sender's request contract uses the shared function secret. A public client containing that secret permits unauthorized notification attempts if the endpoint accepts it. Enforce identity and allowed-recipient rules server-side.
- Manual payment confirmation is not proof of gateway settlement. Server-verifiable transaction status is required before delivering paid goods or writing authoritative payment-success records.

These observations are based on repository contents; no credential was tested or intentionally used.

## 8. Local development

### Prerequisites

- Git.
- Flutter SDK on the stable channel, compatible with Dart 3.2+ and the versions in `pubspec.yaml`.
- Android Studio/Android SDK or another supported Android build toolchain for Android runs.
- A configured Firebase project and platform config.
- Supabase project access for testing Edge Functions.
- Paystack test credentials for payment integration tests.

### Clone and install

```bash
git clone https://github.com/AffanNamu/PFB.git
cd PFB
flutter --version
flutter pub get
```

### Run on an available device/browser

```bash
# List targets
flutter devices

# Android or another selected device
flutter run

# Flutter Web
flutter config --enable-web
flutter run -d chrome
```

### Static checks and tests

```bash
flutter analyze
flutter test
```

The repository includes Flutter test dependencies, but this review did not execute the application, run the test suite, or validate live Firebase/Supabase/Paystack configuration. Treat these commands as suggested checks, not as a report of passing tests.

### Build artifacts

```bash
# Web release output
flutter build web --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

A release build requires the correct environment configuration and protected signing setup.

## 9. CI/CD and deployment

### 9.1 Flutter Web

The workflow at `.github/workflows/deploy.yml` is named **Build and Deploy Flutter Web** and triggers on pushes to `main`. It:
1. Checks out the repository.
2. Installs Flutter stable.
3. Enables Flutter Web.
4. Generates the Web scaffold if it is absent.
5. Ensures referenced assets exist (including a fallback asset-download step).
6. Cleans and resolves dependencies.
7. Runs `flutter build web --release`.
8. injects a build fingerprint into the output for cache busting.
9. Deploys to Firebase Hosting using CI configuration/secrets.

Review the remainder of the workflow in GitHub for the exact Firebase CLI deployment command and required secret names before operating it.

### 9.2 Android workflows

The repository has multiple Android-related workflows under `.github/workflows/`. Inspect which ones are enabled and intentionally maintained before relying on them; several filenames appear generic or experimental. The Android Gradle configuration declares namespace/application ID `com.pfb.app`, compile/target SDK 36, NDK 28.2, Java 17, minimum SDK 26, and application version 1.2.0/version code 1.

The build script falls back to debug signing if the release keystore properties file is absent. This is convenient for CI experimentation but is not acceptable as an unnoticed production-release configuration. Confirm that release artifacts use the intended release signing key, and protect the keystore/passwords outside the repository.

### 9.3 Supabase Edge Functions

Function source lives under `supabase/functions/<function-name>/index.ts`. Set the secrets first, then deploy using the Supabase CLI or dashboard. Confirm the deployed function URL matches `AppConstants`, and test expected success and error paths with test credentials.

Suggested function tests:
- Reject non-POST requests.
- Reject missing/invalid authorization.
- Reject invalid request fields.
- Fail safely when secrets are missing.
- Verify Paystack transaction status server-side before treating an attempt as paid.
- Confirm FCM requests authenticate callers and restrict notification recipients.
- Ensure logs don't disclose bearer secrets, service-account private keys or payment details.

## 10. Quality, testing and operational guidance

Before releasing:
- Run `flutter analyze` and `flutter test`.
- Test registration/login, Google sign-in, redirect restoration on Web and sign-out.
- Test product loading, image failures, stock/variant combinations, cart persistence and checkout totals.
- Exercise payment failure, cancellation, duplicate return, delayed webhook and repeated callback paths.
- Test order statuses, assigned-admin visibility, paused/full admin, missing coverage, escalation and manual reassignment.
- Test location handling with known coordinates in several regions; validate candidate distance/radius calculations against expected values.
- Test POS payment methods, discounts at limits, cash change, receipt persistence, PDF/print/share flows and analytics reconciliation.
- Test FCM while app is foregrounded, backgrounded, terminated, logged out and across token refresh.
- Verify Firestore rules using the Firebase Emulator or dedicated test project.
- Test Web/mobile responsive layout and browser authorization domains.
- Validate production-signing and release artifacts in CI.

For business-critical flows, prefer integration tests and emulator-backed tests over UI-only checks. Money, stock, admin authorization, payment fulfilment and assignment should be validated at the trusted backend/database boundary rather than relying solely on client-provided values.

## 11. Known limitations and migration cautions

1. **Payment confirmation:** manual app-side confirmation must not be treated as authoritative proof of Paystack success.
2. **Client-held shared function secret:** the shared Edge Function secret is compiled into the app, so the endpoint is not protected from extraction-based reuse.
3. **Admin assignment coordinates:** order placement currently uses fixed Nigeria-centre coordinates for geographic scoring rather than actual destination coordinates.
4. **Legacy ride model/data:** `RideModel` is documented in source as transitional; review all remaining consumers and Firestore documents before removing it.
5. **Client-side admin checks:** route hiding and UID checks are not substitutes for Firestore Rules/trusted backend authorization.
6. **Large UI files:** some screens are very large and appear to combine UI with orchestration. Refactor incrementally, with regression tests, rather than replacing workflows wholesale.
7. **Receipt ID uniqueness:** random suffix generation needs collision handling if sales volume grows.
8. **Push notification execution:** sends are initiated from service logic, not a robust event queue; transient client/network failures can result in missed events.
9. **Analytics definitions:** reconcile analytics numbers against a known sample of orders/POS sales before using them for accounting or performance compensation.
10. **Build/security hygiene:** release signing/key-like files and environment configuration should be checked and rotated as needed.

## 12. Recommended maintenance roadmap

### Priority 0 — Security and financial correctness
- Remove the client-side shared Edge Function secret; validate Firebase Auth tokens in Edge Functions and authorize each request.
- Implement server-to-server Paystack verification/webhooks and idempotent fulfilment.
- Audit Firestore Rules for every collection and subcollection, especially user/admin access, prices, payment records and POS sales.
- Review/rotate any credentials or signing keys committed to Git and purge exposed secrets from history where necessary.
- Ensure privileged actions use trusted server-side authorization.

### Priority 1 — Operational correctness
- Replace fixed destination coordinates with validated customer coordinates from the address/map flow.
- Define a single order status enum/state machine and centrally validate transitions.
- Reconcile order, payment and POS monetary calculations at the persistence boundary.
- Add idempotency keys and duplicate callback/webhook protection.
- Remove stale FCM tokens and keep delivery results for audit.

### Priority 2 — Maintainability and reliability
- Add repository/service tests for payment, admin assignment, discount calculations and status transitions.
- Add structured logging with request IDs while redacting private data.
- Move notification dispatch to a backend event queue/trigger with retries and dead-letter visibility.
- Break down oversized feature screens into presentation widgets and controllers/providers.
- Document and test the Firestore schema and indexes alongside code changes.

## 13. Contribution guidelines

For safe contributions:
1. Read the relevant feature screen, model, service, and existing operational notes before making edits.
2. Preserve existing Firestore field names and legacy fallbacks unless there is a migration plan.
3. Keep pricing and status changes synchronized between checkout, order records, notifications and analytics.
4. Avoid placing secrets in Dart code, committed JSON, workflow files or logs.
5. Add tests for business logic, especially assignment, order transitions, discounts and payment state.
6. Verify Web and Android builds when changing shared code.
7. Make database/security-rule changes additive where practical and test against a non-production Firebase project first.

## 14. Reference files

- `lib/main.dart` — startup/bootstrap and Web auth restoration.
- `lib/app.dart` — top-level application widget, theme and route wiring.
- `lib/core/routing/app_router.dart` — named route implementation.
- `lib/core/constants/app_constants.dart` — collection names, endpoint URLs and defaults.
- `lib/services/firebase_auth_service.dart` — authentication flows.
- `lib/services/firebase_service.dart` — Firestore business operations, assignment and notifications.
- `lib/services/payment_service.dart` — payment attempts and checkout initialization.
- `lib/services/fcm_service.dart` — device token and push receive lifecycle.
- `lib/features/pos/data/repositories/pos_repository.dart` — POS calculations and persistence.
- `lib/features/admin/presentation/screens/super_admin_analytics_screen.dart` — analytics view.
- `supabase/functions/init-paystack-transaction/index.ts` — Paystack initialization endpoint.
- `supabase/functions/send-fcm-notification/index.ts` — FCM HTTP v1 sender.
- `PAYSTACK_SUPABASE_DEPLOYMENT_GUIDE.md` — original payment deployment notes.
- `FCM_APP_FLOW_WIRING_DOCUMENTATION.md` — notification flow notes.
- `SUPER_ADMIN_ANALYTICS_DOCUMENTATION.md` and its numbered parts — analytics notes.
- `APP_DOCUMENTATION_PART_4.md` through `APP_DOCUMENTATION_PART_9.md` — admin assignment and operations notes.

## 15. Disclaimer

This document is based on source and Markdown files visible on the repository's `main` branch at the time of review. The repository's existing README is empty. No app build, automated test suite, live backend request, payment, notification delivery or production deployment was run as part of this documentation pass. Always verify configuration and behavior in a safe test environment before using this document as a release checklist.
