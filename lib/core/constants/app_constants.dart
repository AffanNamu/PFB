// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = "Phlakes Fabrics";

  // ── Super Admin UIDs ──────────────────────────────────────────────────────
  static const List<String> superAdminUids = [
    "Z4KfPSRXJ7ZX3yZU9esowKqeRVJ3",
  
    // mohammedauwalnassra@gmail.com
    "zeFovG6ctXWTNTCwiH68RXTv8NJ2",
  ];

  static const String primarySuperAdminUid =
      "DfbaXxItLIMFkY48XF2jBF1qjLC3";

  static bool isSuperAdminUid(String? uid) {
    if (uid == null || uid.trim().isEmpty) return false;
    return superAdminUids.contains(uid.trim());
  }

  // ── Existing Collections ──────────────────────────────────────────────────
  static const String productsCollection =
      "products";
  static const String adminsCollection = "admins";
  static const String ordersCollection = "orders";
  static const String usersCollection = "users";
  static const String ridesCollection = "rides";
  static const String categoriesCollection =
      "categories";
  static const String paymentsCollection = "payments";
  static const String paymentAttemptsCollection =
      "payment_attempts";
  static const String appSettingsCollection =
      "app_settings";

  // ── POS Collections ───────────────────────────────────────────────────────
  static const String posSalesCollection = "pos_sales";
  static const String posReceiptsCollection =
      "pos_receipts";
  static const String posAnalyticsCollection =
      "pos_analytics";
  static const String adminPerformanceCollection =
      "admin_performance";

  // ── POS Branch Defaults ───────────────────────────────────────────────────
  static const String defaultBranchId = "main";
  static const String defaultBranchName =
      "Main Branch";

  // ── POS Discount Limits ───────────────────────────────────────────────────
  static const double maxCashierDiscountPercent = 20.0;
  static const double maxCashierDiscountFixed = 5000.0;

  // ── Ride / Delivery Fares ─────────────────────────────────────────────────
  static const double rideBaseFare = 500;
  static const double ridePricePerKm = 100;
  static const double deliveryBaseFare = 700;
  static const double deliveryPricePerKm = 120;

  // ── Defaults ──────────────────────────────────────────────────────────────
  static const String defaultVendorLocation = "Nigeria";
  static const double nigeriaCenterLat = 9.0820;
  static const double nigeriaCenterLng = 8.6753;

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseProjectUrl =
      'https://twrinntnsfqxslbauotw.supabase.co';

  static const String supabaseFcmFunctionUrl =
      'https://twrinntnsfqxslbauotw.supabase.co/functions/v1/send-fcm-notification';

  static const String supabasePaystackInitializeFunctionUrl =
      'https://twrinntnsfqxslbauotw.supabase.co/functions/v1/init-paystack-transaction';

  static const String supabaseFunctionSecret =
      'REPLACE_WITH_EDGE_FUNCTION_SECRET';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cmlubnRuc2ZxeHNsYmF1b3R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMzAxMjEsImV4cCI6MjA4OTYwNjEyMX0.DSuXvHDnG8a_1mTqyp3wFpchDM6nQfYd5b0Z2tCg22M';

  static const String supabasePublishableKey =
      'sb_publishable_oDEycW7NtKZG37rR2PtJjg_L3TkIw7T';

  static const String paystackPublicKey =
      'pk_test_5ca62bad3a4e7a85aed9adcf6846d50cb6292a9a';
}
