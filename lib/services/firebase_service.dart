import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/models/app_notification_model.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/supabase_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Admin Assignment Result ────────────────────────────────────────────────────

class AdminAssignmentResult {
  final String? adminUid;
  final String? adminEmail;
  final String? adminName;
  final double? adminLat;
  final double? adminLng;
  final double? distanceKm;
  final String matchedState;
  final String matchedArea;
  final String assignmentMethod;
  final int activeLoad;
  final bool escalatedToSuperAdmin;

  const AdminAssignmentResult({
    required this.adminUid,
    required this.adminEmail,
    required this.adminName,
    required this.adminLat,
    required this.adminLng,
    required this.distanceKm,
    this.matchedState = '',
    this.matchedArea = '',
    this.assignmentMethod = '',
    this.activeLoad = 0,
    this.escalatedToSuperAdmin = false,
  });

  bool get hasAssignment => adminUid != null && adminUid!.trim().isNotEmpty;
}

// ── Firebase Service ───────────────────────────────────────────────────────────

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final SupabaseNotificationService _notificationService =
      SupabaseNotificationService();

  User? get currentUser => auth.currentUser;

  bool get isSuperAdmin => AppConstants.isSuperAdminUid(currentUser?.uid);

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      firestore.collection('app_settings').doc('general');

  // ── Nigerian States ──────────────────────────────────────────────────────────

  List<String> get nigerianStates => const [
        'Abia',
        'Adamawa',
        'Akwa Ibom',
        'Anambra',
        'Bauchi',
        'Bayelsa',
        'Benue',
        'Borno',
        'Cross River',
        'Delta',
        'Ebonyi',
        'Edo',
        'Ekiti',
        'Enugu',
        'FCT',
        'Abuja',
        'Gombe',
        'Imo',
        'Jigawa',
        'Kaduna',
        'Kano',
        'Katsina',
        'Kebbi',
        'Kogi',
        'Kwara',
        'Lagos',
        'Nasarawa',
        'Niger',
        'Ogun',
        'Ondo',
        'Osun',
        'Oyo',
        'Plateau',
        'Rivers',
        'Sokoto',
        'Taraba',
        'Yobe',
        'Zamfara',
      ];

  String _inferStateFromAddress(String address) {
    final lower = address.toLowerCase();
    for (final state in nigerianStates) {
      if (lower.contains(state.toLowerCase())) return state;
    }
    if (lower.contains('federal capital territory')) return 'FCT';
    return '';
  }

  // ── Safe Initializers ────────────────────────────────────────────────────────

  Future<void> seedDefaultAppSettingsSafely() async {
    try {
      await seedDefaultAppSettings();
    } catch (_) {}
  }

  Future<void> seedDefaultCategoriesIfMissingSafely() async {
    try {
      await seedDefaultCategoriesIfMissing();
    } catch (_) {}
  }

  Future<void> ensureUserProfileSafely() async {
    try {
      await ensureUserProfile();
    } catch (_) {}
  }

  Future<void> syncLocalCartToFirestoreSafely() async {
    try {
      await syncLocalCartToFirestore();
    } catch (_) {}
  }

  // ── Token Helpers ────────────────────────────────────────────────────────────

  Future<List<String>> _readUserTokens(String uid) async {
    final doc =
        await firestore.collection(AppConstants.usersCollection).doc(uid).get();
    final data = doc.data() ?? {};
    return List<String>.from(data['fcmTokens'] ?? []);
  }

  Future<List<String>> _readAdminTokens(String uid) async {
    final doc = await firestore
        .collection(AppConstants.adminsCollection)
        .doc(uid)
        .get();
    final data = doc.data() ?? {};
    return List<String>.from(data['fcmTokens'] ?? []);
  }

  // ── Notification Subcollections ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _notificationSubcollection({
    required String rootCollection,
    required String uid,
  }) {
    return firestore.collection(rootCollection).doc(uid).collection('notifications');
  }

  CollectionReference<Map<String, dynamic>> _userNotifications(String uid) {
    return _notificationSubcollection(
      rootCollection: AppConstants.usersCollection,
      uid: uid,
    );
  }

  CollectionReference<Map<String, dynamic>> _adminNotifications(String uid) {
    return _notificationSubcollection(
      rootCollection: AppConstants.adminsCollection,
      uid: uid,
    );
  }

  Future<bool> _hasAdminNotificationInbox(String uid) async {
    if (AppConstants.isSuperAdminUid(uid)) return true;
    try {
      final doc = await firestore.collection(AppConstants.adminsCollection).doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  List<AppNotificationModel> _mapNotificationDocs({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required String recipientCollection,
  }) {
    return snapshot.docs
        .map((doc) => AppNotificationModel.fromMap(
              doc.id,
              doc.data(),
              recipientCollection: recipientCollection,
            ))
        .toList();
  }

  Future<String> _createNotificationRecord({
    required String rootCollection,
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    String? targetScreen,
    String? targetId,
    String source = 'system',
  }) async {
    final ref = _notificationSubcollection(
      rootCollection: rootCollection,
      uid: recipientUid,
    ).doc();

    await ref.set({
      'notificationId': ref.id,
      'notificationCollection': rootCollection,
      'title': title.trim(),
      'body': body.trim(),
      'type': type.trim(),
      'targetScreen': (targetScreen ?? '').trim(),
      'targetId': (targetId ?? '').trim(),
      'isRead': false,
      'source': source,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return ref.id;
  }

  // ── Watch Notifications ──────────────────────────────────────────────────────

  Stream<List<AppNotificationModel>> watchNotifications() {
    final user = currentUser;
    if (user == null) return Stream.value(const <AppNotificationModel>[]);

    final controller = StreamController<List<AppNotificationModel>>();
    List<AppNotificationModel> userNotifications = const [];
    List<AppNotificationModel> adminNotifications = const [];

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? userSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? adminSub;

    void emit() {
      if (controller.isClosed) return;
      final merged = [...userNotifications, ...adminNotifications]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(merged);
    }

    controller.onListen = () {
      () async {
        try {
          userSub = _userNotifications(user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              userNotifications = _mapNotificationDocs(
                snapshot: snapshot,
                recipientCollection: AppConstants.usersCollection,
              );
              emit();
            },
            onError: (error, stackTrace) {
              if (!controller.isClosed) controller.addError(error, stackTrace);
            },
          );

          final hasAdminInbox = await _hasAdminNotificationInbox(user.uid);
          if (!hasAdminInbox) {
            emit();
            return;
          }

          adminSub = _adminNotifications(user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen(
            (snapshot) {
              adminNotifications = _mapNotificationDocs(
                snapshot: snapshot,
                recipientCollection: AppConstants.adminsCollection,
              );
              emit();
            },
            onError: (error, stackTrace) {
              if (!controller.isClosed) controller.addError(error, stackTrace);
            },
          );
        } catch (error, stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        }
      }();
    };

    controller.onCancel = () async {
      await userSub?.cancel();
      await adminSub?.cancel();
    };

    return controller.stream;
  }

  Stream<List<AppNotificationModel>> watchAdminNotifications() {
    final user = currentUser;
    if (user == null) return Stream.value(const <AppNotificationModel>[]);

    return _adminNotifications(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => _mapNotificationDocs(
              snapshot: snapshot,
              recipientCollection: AppConstants.adminsCollection,
            ));
  }

  Stream<int> watchUnreadNotificationCount() {
    return watchNotifications()
        .map((items) => items.where((item) => !item.isRead).length);
  }

  Future<void> markNotificationAsRead(
    String notificationId, {
    String? recipientCollection,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final trimmedId = notificationId.trim();
    if (trimmedId.isEmpty) return;

    final roots = <String>{};
    if (recipientCollection != null && recipientCollection.trim().isNotEmpty) {
      roots.add(recipientCollection.trim());
    }
    roots.add(AppConstants.usersCollection);
    if (await _hasAdminNotificationInbox(user.uid)) {
      roots.add(AppConstants.adminsCollection);
    }

    for (final root in roots) {
      try {
        final ref = _notificationSubcollection(
          rootCollection: root,
          uid: user.uid,
        ).doc(trimmedId);

        final doc = await ref.get();
        if (!doc.exists) continue;

        await ref.set({
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        return;
      } catch (_) {}
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = currentUser;
    if (user == null) return;

    final collections = <CollectionReference<Map<String, dynamic>>>[
      _userNotifications(user.uid),
    ];

    if (await _hasAdminNotificationInbox(user.uid)) {
      collections.add(_adminNotifications(user.uid));
    }

    final batch = firestore.batch();
    final readAt = DateTime.now().toIso8601String();
    var hasWrites = false;

    for (final collection in collections) {
      try {
        final snapshot = await collection.where('isRead', isEqualTo: false).get();
        for (final doc in snapshot.docs) {
          batch.set(doc.reference, {'isRead': true, 'readAt': readAt}, SetOptions(merge: true));
          hasWrites = true;
        }
      } catch (_) {}
    }

    if (hasWrites) await batch.commit();
  }

  Future<void> deleteNotification(
    String notificationId, {
    required String recipientCollection,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final trimmedId = notificationId.trim();
    if (trimmedId.isEmpty) return;

    try {
      await _notificationSubcollection(
        rootCollection: recipientCollection,
        uid: user.uid,
      ).doc(trimmedId).delete();
    } catch (_) {}
  }

  Future<int> cleanupOldNotifications({int days = 30}) async {
    final user = currentUser;
    if (user == null) return 0;

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = cutoff.toIso8601String();

    final collections = <CollectionReference<Map<String, dynamic>>>[
      _userNotifications(user.uid),
    ];

    if (await _hasAdminNotificationInbox(user.uid)) {
      collections.add(_adminNotifications(user.uid));
    }

    int deletedCount = 0;

    for (final collection in collections) {
      try {
        final snapshot =
            await collection.where('createdAt', isLessThan: cutoffStr).get();

        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        if (snapshot.docs.isNotEmpty) await batch.commit();
      } catch (_) {}
    }

    return deletedCount;
  }

  // ── Notify Helpers ───────────────────────────────────────────────────────────

  Future<void> _notifyUser({
    required String userUid,
    required String title,
    required String body,
    required String type,
    String? targetScreen,
    String? targetId,
  }) async {
    String? notificationId;

    try {
      notificationId = await _createNotificationRecord(
        rootCollection: AppConstants.usersCollection,
        recipientUid: userUid,
        title: title,
        body: body,
        type: type,
        targetScreen: targetScreen,
        targetId: targetId,
      );
    } catch (_) {}

    try {
      final tokens = await _readUserTokens(userUid);
      await _notificationService.sendPush(
        tokens: tokens,
        title: title,
        body: body,
        type: type,
        targetScreen: targetScreen,
        targetId: targetId,
        notificationId: notificationId,
        notificationCollection: AppConstants.usersCollection,
      );
    } catch (_) {}
  }

  Future<void> _notifyAdmin({
    required String adminUid,
    required String title,
    required String body,
    required String type,
    String? targetScreen,
    String? targetId,
  }) async {
    String? notificationId;

    try {
      notificationId = await _createNotificationRecord(
        rootCollection: AppConstants.adminsCollection,
        recipientUid: adminUid,
        title: title,
        body: body,
        type: type,
        targetScreen: targetScreen,
        targetId: targetId,
      );
    } catch (_) {}

    try {
      final tokens = await _readAdminTokens(adminUid);
      await _notificationService.sendPush(
        tokens: tokens,
        title: title,
        body: body,
        type: type,
        targetScreen: targetScreen,
        targetId: targetId,
        notificationId: notificationId,
        notificationCollection: AppConstants.adminsCollection,
      );
    } catch (_) {}
  }

  Future<void> _notifySuperAdminEscalation({
    required String title,
    required String body,
    required String targetId,
    required String type,
  }) async {
    for (final superAdminUid in AppConstants.superAdminUids) {
      String? notificationId;

      try {
        notificationId = await _createNotificationRecord(
          rootCollection: AppConstants.adminsCollection,
          recipientUid: superAdminUid,
          title: title,
          body: body,
          type: type,
          targetScreen: 'admin_escalation_dashboard',
          targetId: targetId,
        );
      } catch (_) {}

      try {
        final tokens = await _readAdminTokens(superAdminUid);
        await _notificationService.sendPush(
          tokens: tokens,
          title: title,
          body: body,
          type: type,
          targetScreen: 'admin_escalation_dashboard',
          targetId: targetId,
          notificationId: notificationId,
          notificationCollection: AppConstants.adminsCollection,
        );
      } catch (_) {}
    }
  }

  // ── Admin Management ─────────────────────────────────────────────────────────

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    if (AppConstants.isSuperAdminUid(user.uid)) return true;

    try {
      final uidDoc =
          await firestore.collection(AppConstants.adminsCollection).doc(user.uid).get();
      if (uidDoc.exists) return true;
    } catch (_) {
      return false;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    try {
      final emailSnapshot = await firestore
          .collection(AppConstants.adminsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailSnapshot.docs.isEmpty) return false;

      final oldDoc = emailSnapshot.docs.first;
      final oldData = oldDoc.data();

      try {
        await firestore.collection(AppConstants.adminsCollection).doc(user.uid).set({
          ...oldData,
          'uid': user.uid,
          'email': email,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        if (oldDoc.id != user.uid) {
          try {
            await firestore.collection(AppConstants.adminsCollection).doc(oldDoc.id).delete();
          } catch (_) {}
        }

        return true;
      } catch (_) {
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> addAdmin({
    required String uid,
    required String email,
  }) async {
    final addedBy = currentUser?.uid ?? '';
    await firestore.collection(AppConstants.adminsCollection).doc(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'displayName': email.split('@').first,
      'role': 'admin',
      'addedBy': addedBy,
      'baseAddress': '',
      'baseLat': null,
      'baseLng': null,
      'serviceRadiusKm': 30.0,
      'coverageStates': [],
      'coverageAreas': [],
      'isActive': true,
      'maxActiveAssignments': 20,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAdminCoverage({
    required String adminUid,
    required String email,
    required String displayName,
    required String baseAddress,
    required double baseLat,
    required double baseLng,
    required double serviceRadiusKm,
    List<String> coverageStates = const [],
    List<String> coverageAreas = const [],
  }) async {
    final inferredState = _inferStateFromAddress(baseAddress);
    final finalStates = {
      ...coverageStates.where((e) => e.trim().isNotEmpty),
      if (inferredState.isNotEmpty) inferredState,
    }.toList();

    await firestore.collection(AppConstants.adminsCollection).doc(adminUid).set({
      'uid': adminUid,
      'email': email,
      'displayName': displayName,
      'role': 'admin',
      'baseAddress': baseAddress,
      'baseLat': baseLat,
      'baseLng': baseLng,
      'serviceRadiusKm': serviceRadiusKm,
      'coverageStates': finalStates,
      'coverageAreas': coverageAreas,
      'isActive': true,
      'maxActiveAssignments': 20,
      'updatedAt': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAdminWorkloadConfig({
    required String adminUid,
    required bool isActive,
    required int maxActiveAssignments,
  }) async {
    await firestore.collection(AppConstants.adminsCollection).doc(adminUid).set({
      'isActive': isActive,
      'maxActiveAssignments': maxActiveAssignments,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchAdmins() {
    return firestore.collection(AppConstants.adminsCollection).snapshots().map(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList()
            ..sort(
              (a, b) => (b['createdAt'] ?? '')
                  .toString()
                  .compareTo((a['createdAt'] ?? '').toString()),
            ),
        );
  }

  // ── App Settings ─────────────────────────────────────────────────────────────

  Future<String> getVendorPickupAddress() async {
    final doc = await _settingsDoc.get();
    final data = doc.data() ?? {};
    final value = (data['vendorPickupAddress'] ?? '').toString().trim();
    if (value.isNotEmpty) return value;
    return AppConstants.defaultVendorLocation;
  }

  Stream<String> watchVendorPickupAddress() {
    return _settingsDoc.snapshots().map((doc) {
      final data = doc.data() ?? {};
      final value = (data['vendorPickupAddress'] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
      return AppConstants.defaultVendorLocation;
    });
  }

  Future<void> updateVendorPickupAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) throw Exception('Vendor pickup address cannot be empty');

    await _settingsDoc.set({
      'vendorPickupAddress': trimmed,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultAppSettings() async {
    final doc = await _settingsDoc.get();
    if (!doc.exists) {
      await _settingsDoc.set({
        'vendorPickupAddress': AppConstants.defaultVendorLocation,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return;
    }

    final data = doc.data() ?? {};
    final existing = (data['vendorPickupAddress'] ?? '').toString().trim();
    if (existing.isEmpty) {
      await _settingsDoc.set({
        'vendorPickupAddress': AppConstants.defaultVendorLocation,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  // ── Distance Helper ──────────────────────────────────────────────────────────

  double _toRadians(double degree) => degree * (math.pi / 180);

  double _distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  // ── Admin Assignment Engine ──────────────────────────────────────────────────

  Future<int> _countAdminActiveAssignments(String adminUid) async {
    final ordersSnapshot = await firestore
        .collection(AppConstants.ordersCollection)
        .where('assignedAdminUid', isEqualTo: adminUid)
        .get();

    return ordersSnapshot.docs.where((doc) {
      final status = (doc.data()['status'] ?? '').toString();
      return status != 'delivered' && status != 'cancelled';
    }).length;
  }

  Future<AdminAssignmentResult> _superAdminFallback({
    required String destinationState,
  }) async {
    final fallbackUid = AppConstants.primarySuperAdminUid;
    final superAdminDoc =
        await firestore.collection(AppConstants.adminsCollection).doc(fallbackUid).get();
    final data = superAdminDoc.data();

    if (data != null) {
      return AdminAssignmentResult(
        adminUid: fallbackUid,
        adminEmail: (data['email'] ?? '').toString(),
        adminName: (data['displayName'] ?? 'Super Admin').toString(),
        adminLat: (data['baseLat'] as num?)?.toDouble(),
        adminLng: (data['baseLng'] as num?)?.toDouble(),
        distanceKm: null,
        matchedState: destinationState,
        matchedArea: '',
        assignmentMethod: 'super_admin_fallback',
        activeLoad: 0,
        escalatedToSuperAdmin: true,
      );
    }

    return AdminAssignmentResult(
      adminUid: fallbackUid,
      adminEmail: '',
      adminName: 'Super Admin',
      adminLat: null,
      adminLng: null,
      distanceKm: null,
      matchedState: destinationState,
      matchedArea: '',
      assignmentMethod: 'super_admin_fallback',
      activeLoad: 0,
      escalatedToSuperAdmin: true,
    );
  }

  Future<AdminAssignmentResult> findNearestAdmin({
    required double targetLat,
    required double targetLng,
    required String destinationAddress,
  }) async {
    final snapshot = await firestore.collection(AppConstants.adminsCollection).get();
    final destinationState = _inferStateFromAddress(destinationAddress);
    final destinationLower = destinationAddress.toLowerCase();

    final stateMatchedDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final states = List<String>.from(data['coverageStates'] ?? []);
      return destinationState.isNotEmpty &&
          states.map((e) => e.toLowerCase()).contains(destinationState.toLowerCase());
    }).toList();

    final areaMatchedDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final areas = List<String>.from(data['coverageAreas'] ?? []);
      return areas.any((area) => destinationLower.contains(area.toLowerCase()));
    }).toList();

    List<QueryDocumentSnapshot<Map<String, dynamic>>> candidates;
    String method = 'radius';

    if (areaMatchedDocs.isNotEmpty) {
      candidates = areaMatchedDocs;
      method = 'area';
    } else if (stateMatchedDocs.isNotEmpty) {
      candidates = stateMatchedDocs;
      method = 'state';
    } else {
      candidates = snapshot.docs;
      method = 'radius';
    }

    AdminAssignmentResult? best;
    double? bestScore;

    for (final doc in candidates) {
      if (AppConstants.isSuperAdminUid(doc.id)) continue;

      final data = doc.data();
      final isActive = (data['isActive'] ?? true) == true;
      if (!isActive) continue;

      final lat = (data['baseLat'] as num?)?.toDouble();
      final lng = (data['baseLng'] as num?)?.toDouble();
      final radius = ((data['serviceRadiusKm'] ?? 30) as num).toDouble();
      final maxActiveAssignments = ((data['maxActiveAssignments'] ?? 20) as num).toInt();

      if (lat == null || lng == null) continue;

      final distance = _distanceKm(
        lat1: targetLat,
        lng1: targetLng,
        lat2: lat,
        lng2: lng,
      );

      final states = List<String>.from(data['coverageStates'] ?? []);
      final areas = List<String>.from(data['coverageAreas'] ?? []);

      final stateMatch = destinationState.isNotEmpty &&
          states.map((e) => e.toLowerCase()).contains(destinationState.toLowerCase());

      final matchedArea = areas.firstWhere(
        (area) => destinationLower.contains(area.toLowerCase()),
        orElse: () => '',
      );

      final allowed = method == 'radius'
          ? distance <= radius
          : (stateMatch || matchedArea.isNotEmpty || distance <= radius);

      if (!allowed) continue;

      final activeLoad = await _countAdminActiveAssignments(doc.id);
      if (activeLoad >= maxActiveAssignments) continue;

      double score = distance + (activeLoad * 3);
      if (matchedArea.isNotEmpty) {
        score -= 8;
      } else if (stateMatch) {
        score -= 4;
      }

      if (bestScore == null || score < bestScore) {
        bestScore = score;
        best = AdminAssignmentResult(
          adminUid: doc.id,
          adminEmail: (data['email'] ?? '').toString(),
          adminName: (data['displayName'] ?? data['email'] ?? '').toString(),
          adminLat: lat,
          adminLng: lng,
          distanceKm: distance,
          matchedState: stateMatch ? destinationState : '',
          matchedArea: matchedArea,
          assignmentMethod:
              method == 'radius' && activeLoad > 0 ? 'workload_radius' : method,
          activeLoad: activeLoad,
          escalatedToSuperAdmin: false,
        );
      }
    }

    if (best != null) return best;
    return _superAdminFallback(destinationState: destinationState);
  }

  // ── Dashboard Counts ─────────────────────────────────────────────────────────

  Stream<int> watchProductsCount() {
    return firestore.collection(AppConstants.productsCollection).snapshots().map((s) => s.docs.length);
  }

  Stream<int> watchOrdersCount() {
    return firestore.collection(AppConstants.ordersCollection).snapshots().map((s) => s.docs.length);
  }

  Stream<int> watchAssignedOrdersCount() {
    final user = currentUser;
    if (user == null) return Stream.value(0);
    return firestore
        .collection(AppConstants.ordersCollection)
        .where('assignedAdminUid', isEqualTo: user.uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> watchAdminsCount() {
    return firestore
        .collection(AppConstants.adminsCollection)
        .snapshots()
        .map((s) => s.docs.length + AppConstants.superAdminUids.length);
  }

  Stream<int> watchAssignedActiveWorkloadCount() {
    final user = currentUser;
    if (user == null) return Stream.value(0);

    return firestore
        .collection(AppConstants.ordersCollection)
        .where('assignedAdminUid', isEqualTo: user.uid)
        .snapshots()
        .map((s) {
      return s.docs.where((doc) {
        final status = (doc.data()['status'] ?? '').toString();
        return status != 'delivered' && status != 'cancelled';
      }).length;
    });
  }

  // ── Recent Admin Activity ────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchRecentAdminActivity() {
    final productStream = firestore
        .collection(AppConstants.productsCollection)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return {
                'type': 'product',
                'title': 'Product: ${data['name'] ?? 'Unnamed'}',
                'subtitle': '₦${data['price'] ?? 0} · ${data['fabricType'] ?? 'General'}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    final orderStream = firestore
        .collection(AppConstants.ordersCollection)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return {
                'type': 'order',
                'title': 'Order: ${doc.id.substring(0, 8)}',
                'subtitle': 'Status: ${data['status'] ?? 'pending'}',
                'createdAt': data['createdAt'] ?? '',
              };
            }).toList());

    return productStream.asyncMap((products) async {
      final orders = await orderStream.first;
      final merged = [...products, ...orders];
      merged.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
      return merged.take(8).toList();
    });
  }

  // ── TEXTILE CATEGORIES ───────────────────────────────────────────────────────

  static const List<String> _defaultTextileCategories = [
    'General',
    'Trending',
    'Featured',
    'Ankara',
    'Lace',
    'Aso Oke',
    'Chiffon',
    'Cotton',
    'Silk',
    'Linen',
    'Adire',
    'George',
    'Velvet',
    'Kente',
    'Native Wear',
    'Wedding Collection',
    'New Arrivals',
    'Best Sellers',
  ];

  Stream<List<String>> watchCategories() {
    return firestore.collection('categories').orderBy('name').snapshots().map((snapshot) {
      final dbCategories = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final merged = <String>{
        ..._defaultTextileCategories,
        ...dbCategories,
      }.toList()
        ..sort();

      return merged;
    });
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await firestore.collection('categories').doc(trimmed.toLowerCase()).set({
      'name': trimmed,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeCategory(String name) async {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    await firestore.collection('categories').doc(trimmed).delete();
  }

  Future<void> seedDefaultCategoriesIfMissing() async {
    final textileDefaults = [
      'General',
      'Trending',
      'Featured',
      'Ankara',
      'Lace',
      'Aso Oke',
      'Chiffon',
      'Cotton',
      'Silk',
      'Linen',
      'Adire',
      'George',
      'Velvet',
      'Kente',
      'Native Wear',
      'Wedding Collection',
      'New Arrivals',
      'Best Sellers',
    ];

    for (final category in textileDefaults) {
      final ref = firestore.collection('categories').doc(category.toLowerCase().replaceAll(' ', '_'));
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({'name': category, 'createdAt': DateTime.now().toIso8601String()});
      }
    }
  }

  // ── User Profile ─────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  Future<void> ensureUserProfile() async {
    final user = currentUser;
    if (user == null) return;
    final ref = _userDoc(user.uid);

    try {
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'favorites': [],
          'cart': [],
          'addresses': [],
          'selectedAddress': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        final data = snap.data() ?? {};
        final updates = <String, dynamic>{};

        if (user.displayName != null && user.displayName!.isNotEmpty && data['displayName'] != user.displayName) {
          updates['displayName'] = user.displayName;
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty && data['photoUrl'] != user.photoURL) {
          updates['photoUrl'] = user.photoURL;
        }
        if (user.email != null && user.email!.isNotEmpty && data['email'] != user.email) {
          updates['email'] = user.email;
        }

        if (updates.isNotEmpty) {
          await ref.set(updates, SetOptions(merge: true));
        }
      }
    } catch (_) {}
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) return;
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    await user.updateDisplayName(trimmed);
    await user.reload();

    await _userDoc(user.uid).set({'displayName': trimmed}, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchUserProfile() {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    return _userDoc(user.uid).snapshots().map((doc) => doc.data());
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    final user = currentUser;
    if (user == null) return;
    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) return;

    try {
      await user.updatePhotoURL(trimmed);
      await user.reload();
    } catch (_) {}

    await _userDoc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoUrl': trimmed,
    }, SetOptions(merge: true));
  }

  // ── Addresses ────────────────────────────────────────────────────────────────

  Future<void> addAddress(String address) async {
    final user = currentUser;
    if (user == null || address.trim().isEmpty) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final addresses = List<String>.from(data['addresses'] ?? []);

    addresses.add(address.trim());

    await ref.set({
      'addresses': addresses,
      'selectedAddress': address.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> removeAddress(String address) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    final addresses = List<String>.from(data['addresses'] ?? []);
    final selectedAddress = (data['selectedAddress'] ?? '').toString();

    addresses.remove(address);

    await ref.set({
      'addresses': addresses,
      'selectedAddress': selectedAddress == address
          ? (addresses.isNotEmpty ? addresses.first : '')
          : selectedAddress,
    }, SetOptions(merge: true));
  }

  Future<void> setSelectedAddress(String address) async {
    final user = currentUser;
    if (user == null) return;

    await _userDoc(user.uid).set({'selectedAddress': address.trim()}, SetOptions(merge: true));
  }

  Stream<String> watchSelectedAddress() {
    final user = currentUser;
    if (user == null) return Stream.value('');

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return '';
      return (data['selectedAddress'] ?? '').toString();
    });
  }

  // ── Favourites ───────────────────────────────────────────────────────────────

  Stream<List<String>> watchFavorites() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String>[];
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  Stream<List<ProductModel>> watchFavoriteProducts() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _userDoc(user.uid).snapshots().asyncMap((doc) async {
      final data = doc.data();
      final ids = List<String>.from(data?['favorites'] ?? []);
      if (ids.isEmpty) return <ProductModel>[];

      final snapshot = await firestore.collection(AppConstants.productsCollection).get();
      return snapshot.docs
          .where((doc) => ids.contains(doc.id))
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> toggleFavorite(String productId) async {
    final user = currentUser;
    if (user == null) return;

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final favorites = List<String>.from(data['favorites'] ?? []);

    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }

    await ref.set({'favorites': favorites}, SetOptions(merge: true));
  }

  // ── Cart ─────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchCart() {
    final user = currentUser;
    if (user == null) return Stream.fromFuture(getLocalCart());

    return _userDoc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <Map<String, dynamic>>[];
      return List<Map<String, dynamic>>.from(data['cart'] ?? []);
    });
  }

  Stream<int> watchCartCount() {
    return watchCart()
        .map((cart) => cart.fold<int>(0, (sum, item) => sum + ((item['qty'] ?? 1) as int)));
  }

  Future<void> _saveLocalCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pfb_local_cart', jsonEncode(cart));
  }

  Future<List<Map<String, dynamic>>> getLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pfb_local_cart');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> syncLocalCartToFirestore() async {
    final user = currentUser;
    if (user == null) return;

    final localCart = await getLocalCart();
    if (localCart.isEmpty) return;

    final ref = _userDoc(user.uid);
    await ref.set({'cart': localCart}, SetOptions(merge: true));
    await _saveLocalCart([]);
  }

  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    String? fabricType,
    String? color,
    String? size,
  }) async {
    final user = currentUser;

    if (user == null) {
      final local = await getLocalCart();
      final index = local.indexWhere((e) => e['productId'] == productId);

      if (index >= 0) {
        local[index] = {
          ...local[index],
          'qty': ((local[index]['qty'] ?? 1) as int) + 1,
        };
      } else {
        local.add({
          'productId': productId,
          'name': name,
          'price': price,
          'imageUrl': imageUrl,
          'qty': 1,
          if (fabricType != null && fabricType.isNotEmpty) 'fabricType': fabricType,
          if (color != null && color.isNotEmpty) 'color': color,
          if (size != null && size.isNotEmpty) 'size': size,
        });
      }

      await _saveLocalCart(local);
      return;
    }

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final cart = List<Map<String, dynamic>>.from(data['cart'] ?? []);

    final index = cart.indexWhere((e) => e['productId'] == productId);
    if (index >= 0) {
      final currentQty = (cart[index]['qty'] ?? 1) as int;
      cart[index] = {...cart[index], 'qty': currentQty + 1};
    } else {
      cart.add({
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'qty': 1,
        if (fabricType != null && fabricType.isNotEmpty) 'fabricType': fabricType,
        if (color != null && color.isNotEmpty) 'color': color,
        if (size != null && size.isNotEmpty) 'size': size,
      });
    }

    await ref.set({'cart': cart}, SetOptions(merge: true));
  }

  Future<void> updateCartQty({
    required String productId,
    required int qty,
  }) async {
    final user = currentUser;

    if (user == null) {
      final local = await getLocalCart();
      final index = local.indexWhere((e) => e['productId'] == productId);
      if (index < 0) return;

      if (qty <= 0) {
        local.removeAt(index);
      } else {
        local[index] = {...local[index], 'qty': qty};
      }

      await _saveLocalCart(local);
      return;
    }

    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final cart = List<Map<String, dynamic>>.from(data['cart'] ?? []);

    final index = cart.indexWhere((e) => e['productId'] == productId);
    if (index < 0) return;

    if (qty <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = {...cart[index], 'qty': qty};
    }

    await ref.set({'cart': cart}, SetOptions(merge: true));
  }

  Future<void> clearCart() async {
    final user = currentUser;
    if (user == null) {
      await _saveLocalCart([]);
      return;
    }
    await _userDoc(user.uid).set({'cart': []}, SetOptions(merge: true));
  }

  // ── Orders ───────────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchOrders() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((s) => s.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<OrderModel>> watchAllOrders() {
    return firestore
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<OrderModel>> watchAssignedOrdersForAdmin() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return firestore
        .collection(AppConstants.ordersCollection)
        .where('assignedAdminUid', isEqualTo: user.uid)
        .snapshots()
        .map((s) => s.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<OrderModel>> watchEscalatedOrders() {
    final user = currentUser;
    if (user == null || !AppConstants.isSuperAdminUid(user.uid)) {
      return Stream.value([]);
    }

    return firestore
        .collection(AppConstants.ordersCollection)
        .where('escalatedToSuperAdmin', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await firestore.collection(AppConstants.ordersCollection).doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .set({'status': status}, SetOptions(merge: true));

    try {
      final orderDoc = await firestore.collection(AppConstants.ordersCollection).doc(orderId).get();
      final data = orderDoc.data() ?? {};
      final userId = (data['userId'] ?? '').toString();

      if (userId.isNotEmpty) {
        await _notifyUser(
          userUid: userId,
          title: 'Order Update — Sakash',
          body: _orderStatusMessage(status),
          type: 'order_status_update',
          targetScreen: 'order_detail',
          targetId: orderId,
        );
      }
    } catch (_) {}
  }

  String _orderStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Your order is being processed and prepared for delivery.';
      case 'shipped':
        return 'Your order has been shipped and is on its way to you!';
      case 'delivered':
        return 'Your order has been delivered. Enjoy your purchase! 🎉';
      case 'cancelled':
        return 'Your order has been cancelled. Contact support if you need help.';
      default:
        return 'Your order status has been updated to: $status';
    }
  }

  Future<void> placeOrder(
    List<Map<String, dynamic>> cart, {
    String? couponCode,
    double couponDiscount = 0.0,
    double deliveryFee = 0.0,
    String? paymentReference,
    String paymentStatus = 'paid',
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null || cart.isEmpty) return;

    final itemsSubtotal = cart.fold<double>(
      0,
      (sum, item) =>
          sum + (((item['price'] ?? 0) as num).toDouble() * ((item['qty'] ?? 1) as int)),
    );

    final totalAmount = itemsSubtotal + deliveryFee - couponDiscount;

    String deliveryAddress = 'Customer delivery address';
    try {
      deliveryAddress = await _resolveDeliveryAddress();
    } catch (_) {}

    AdminAssignmentResult adminResult;
    try {
      adminResult = await findNearestAdmin(
        targetLat: 9.0820,
        targetLng: 8.6753,
        destinationAddress: deliveryAddress,
      );
    } catch (_) {
      adminResult = await _superAdminFallback(
        destinationState: _inferStateFromAddress(deliveryAddress),
      );
    }

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    final orderMap = {
      'userId': user.uid,
      'items': cart,
      'totalAmount': totalAmount,
      'itemsSubtotal': itemsSubtotal,
      'deliveryFee': deliveryFee,
      'couponDiscount': couponDiscount,
      'couponCode': couponCode ?? '',
      'paymentReference': paymentReference ?? '',
      'paymentStatus': paymentStatus,
      'notes': notes ?? '',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'assignedAdminUid': adminResult.adminUid ?? '',
      'assignedAdminEmail': adminResult.adminEmail ?? '',
      'assignedAdminName': adminResult.adminName ?? '',
      'assignedAdminDistanceKm': adminResult.distanceKm,
      'assignedAdminState': adminResult.matchedState,
      'assignedAdminArea': adminResult.matchedArea,
      'assignmentMethod': adminResult.assignmentMethod,
      'activeAdminLoad': adminResult.activeLoad,
      'escalatedToSuperAdmin': adminResult.escalatedToSuperAdmin,
    };

    await firestore.collection(AppConstants.ordersCollection).doc(orderId).set(orderMap);

    await clearCart();

    try {
      await _notifyUser(
        userUid: user.uid,
        title: '🎉 Order Placed — Sakash',
        body: 'Your order has been placed successfully. We\'ll keep you updated!',
        type: 'order_created',
        targetScreen: 'order_detail',
        targetId: orderId,
      );
    } catch (_) {}

    if ((adminResult.adminUid ?? '').isNotEmpty) {
      try {
        await _notifyAdmin(
          adminUid: adminResult.adminUid!,
          title: '📦 New Order Assigned',
          body: 'A new order has been assigned to your area. Total: ₦${totalAmount.toStringAsFixed(0)}',
          type: 'admin_assignment_order',
          targetScreen: 'admin_orders',
          targetId: orderId,
        );
      } catch (_) {}
    }

    if (adminResult.escalatedToSuperAdmin) {
      try {
        await _notifySuperAdminEscalation(
          title: '⚠️ Escalated Order',
          body: 'A new order could not be auto-assigned. Manual attention needed.',
          targetId: orderId,
          type: 'escalation_created',
        );
      } catch (_) {}
    }
  }

  Future<String> _resolveDeliveryAddress() async {
    final user = currentUser;
    if (user == null) return 'Customer delivery address';

    final profile = await _userDoc(user.uid).get();
    final data = profile.data() ?? {};
    final selected = (data['selectedAddress'] ?? '').toString().trim();
    final addresses = List<String>.from(data['addresses'] ?? []);

    if (selected.isNotEmpty) return selected;
    if (addresses.isNotEmpty) return addresses.first;

    throw Exception('Please save and select a delivery address before checkout');
  }

  Future<void> reassignOrderToAdmin({
    required String orderId,
    required String adminUid,
    required String adminName,
    required String adminEmail,
  }) async {
    await firestore.collection(AppConstants.ordersCollection).doc(orderId).set({
      'assignedAdminUid': adminUid,
      'assignedAdminName': adminName,
      'assignedAdminEmail': adminEmail,
      'assignedAdminState': '',
      'assignedAdminArea': '',
      'assignmentMethod': 'manual_reassignment',
      'activeAdminLoad': await _countAdminActiveAssignments(adminUid),
      'escalatedToSuperAdmin': false,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    try {
      await _notifyAdmin(
        adminUid: adminUid,
        title: '📦 Order Reassigned — Sakash',
        body: 'An order has been reassigned to you.',
        type: 'admin_request_reassigned',
        targetScreen: 'admin_orders',
        targetId: orderId,
      );
    } catch (_) {}
  }

  // ── Escalation Queue ─────────────────────────────────────────────────────────
  // ✅ FIXED: createdAt is String in OrderModel, do NOT call toIso8601String()

  Stream<List<Map<String, dynamic>>> watchEscalationQueue() {
    final user = currentUser;
    if (user == null || !AppConstants.isSuperAdminUid(user.uid)) {
      return Stream.value([]);
    }

    return watchEscalatedOrders().map((orders) {
      return orders
          .map((order) => {
                'type': 'order',
                'id': order.id,
                'title': 'Escalated Orders',
                'subtitle': order.deliveryAddress,
                'status': order.status,
                'createdAt': order.createdAt, // ✅ fixed
              })
          .toList();
    });
  }

  // ── Products ─────────────────────────────────────────────────────────────────

  Stream<List<ProductModel>> watchAllProducts() {
    return firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchTrendingProducts() {
    return watchAllProducts().map((items) => items.where((item) => item.isTrending).toList());
  }

  Stream<List<ProductModel>> watchNewArrivals({int limit = 10}) {
    return firestore
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchBestSellers({int limit = 10}) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('isBestSeller', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchFeaturedProducts({int limit = 10}) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchProductsByFabricType(
    String fabricType, {
    int limit = 20,
  }) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('fabricType', isEqualTo: fabricType)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchProductsByCategory(
    String category, {
    int limit = 20,
  }) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('category', isEqualTo: category)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchProductsByOccasion(
    String occasion, {
    int limit = 20,
  }) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('occasion', isEqualTo: occasion)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchProductsByGender(
    String gender, {
    int limit = 20,
  }) {
    return firestore
        .collection(AppConstants.productsCollection)
        .where('gender', isEqualTo: gender)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ProductModel>> watchMyUploadedProducts() {
    final user = currentUser;
    if (user == null) return Stream.value([]);
    if (AppConstants.isSuperAdminUid(user.uid)) return watchAllProducts();

    return firestore
        .collection(AppConstants.productsCollection)
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .map((s) => s.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> updateProduct(ProductModel product) async {
    await firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    await firestore.collection(AppConstants.productsCollection).doc(productId).delete();
  }
}
