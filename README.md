# Sakash Collection

Sakash Collection is a Flutter application for textile/fabric commerce, customer orders and delivery coordination, admin operations, and point-of-sale checkout.

## Core modules

- Customer authentication, product catalogue, product detail, favorites, cart and profile.
- Checkout integration that initializes Paystack transactions through a Supabase Edge Function.
- Order history, status updates, delivery tracking and map/location utilities.
- Admin product/order operations, geographic coverage, workload-aware assignment, escalation and reassignment.
- POS dashboard, checkout, discounts, payment recording, receipts and analytics.
- Super-admin analytics for commerce and operational reporting.
- Firebase Cloud Messaging, local notifications and notification-driven navigation.

## Technology

Flutter/Dart, Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, Supabase Edge Functions, Paystack, Firebase Hosting, GitHub Actions, and Flutter map/location packages.

## Read the documentation

**Start here:** [Comprehensive Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md)

The guide covers architecture, features, Firestore collections, data flows, setup, deployment, operational checks, known limitations and security priorities.

## Getting started

Prerequisites: Flutter stable, Dart 3.2 or later (under 4.0), Git, platform build tools, and access to the appropriate Firebase/Supabase project configuration.

```bash
git clone https://github.com/AffanNamu/PFB.git
cd PFB
flutter pub get
flutter run
```

To run Flutter Web:

```bash
flutter config --enable-web
flutter run -d chrome
```

Useful checks:

```bash
flutter analyze
flutter test
```

These are starter commands; Firebase providers/security rules, Supabase function secrets, Paystack settings and signing configuration must be set up separately.

## Important deployment caution

The repository contains client-side payment-return confirmation and a shared Edge Function secret placeholder in the Flutter source. A mobile/web client cannot keep an embedded shared secret confidential, and returning from checkout is not proof that Paystack settled a transaction. Review the security and payment correctness priorities in the [technical documentation](docs/TECHNICAL_DOCUMENTATION.md) before treating payments as production-verified.

## Deployment

A GitHub Actions workflow under `.github/workflows/deploy.yml` builds Flutter Web and deploys it to Firebase Hosting when changes are pushed to `main`. Review the workflow and repository secrets before relying on it. The repository also contains Android-related workflows and Supabase Edge Function source under `supabase/functions/`.

## Repository

https://github.com/AffanNamu/PFB

## Documentation status

Documentation is derived from the repository source and existing technical notes. It does not imply that builds, automated tests, live payments, notifications or deployments have been executed and verified.
