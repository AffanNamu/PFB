// ── Sakash — ride_model.dart ───────────────────────────────────────────────
// This model is KEPT because driver_mode_screen.dart (admin delivery dispatch
// screen) still references it during this transition batch.
//
// ⚠️  DO NOT import RideModel in any new screen or feature.
// ⚠️  This file will be fully deprecated in a future batch when
//     driver_mode_screen is fully converted to use OrderModel.
//
// For now: kept as-is to prevent compilation errors.
// firebase_service.dart no longer writes new ride documents.
// Existing ride documents in Firestore will not affect new orders.

class RideModel {
  final String id;
  final String type;
  final String userId;
  final String pickup;
  final String destination;
  final String rideType;
  final String status;
  final String? driver;
  final double price;
  final String note;
  final String eta;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final double? driverLat;
  final double? driverLng;
  final double distanceKm;
  final double durationMin;
  final String routeGeometry;
  final String? productId;
  final String? orderId;
  final String? addressLabel;
  final String? assignedAdminUid;
  final String? assignedAdminEmail;
  final String? assignedAdminName;
  final double? assignedAdminDistanceKm;
  final String? assignedAdminState;
  final String? assignedAdminArea;
  final String? assignmentMethod;
  final int? activeAdminLoad;
  final bool escalatedToSuperAdmin;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.rideType,
    required this.status,
    required this.driver,
    required this.price,
    required this.note,
    required this.eta,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.driverLat,
    this.driverLng,
    this.distanceKm = 0,
    this.durationMin = 0,
    this.routeGeometry = '',
    this.productId,
    this.orderId,
    this.addressLabel,
    this.assignedAdminUid,
    this.assignedAdminEmail,
    this.assignedAdminName,
    this.assignedAdminDistanceKm,
    this.assignedAdminState,
    this.assignedAdminArea,
    this.assignmentMethod,
    this.activeAdminLoad,
    this.escalatedToSuperAdmin = false,
    required this.createdAt,
  });

  bool get isDelivery => type == 'delivery';
  bool get isActive => status != 'completed' && status != 'cancelled';

  String get readableType {
    if (type == 'delivery') return 'Delivery';
    return 'Ride';
  }

  factory RideModel.fromMap(String id, Map<String, dynamic> map) {
    return RideModel(
      id: id,
      type: (map['type'] ?? 'ride').toString(),
      userId: (map['userId'] ?? '').toString(),
      pickup: (map['pickup'] ?? '').toString(),
      destination: (map['destination'] ?? '').toString(),
      rideType: (map['rideType'] ?? 'car').toString(),
      status: (map['status'] ?? 'searching').toString(),
      driver: map['driver']?.toString(),
      price: ((map['price'] ?? 0) as num).toDouble(),
      note: (map['note'] ?? '').toString(),
      eta: (map['eta'] ?? '').toString(),
      pickupLat: (map['pickupLat'] as num?)?.toDouble(),
      pickupLng: (map['pickupLng'] as num?)?.toDouble(),
      destinationLat: (map['destinationLat'] as num?)?.toDouble(),
      destinationLng: (map['destinationLng'] as num?)?.toDouble(),
      driverLat: (map['driverLat'] as num?)?.toDouble(),
      driverLng: (map['driverLng'] as num?)?.toDouble(),
      distanceKm: ((map['distanceKm'] ?? 0) as num).toDouble(),
      durationMin: ((map['durationMin'] ?? 0) as num).toDouble(),
      routeGeometry: (map['routeGeometry'] ?? '').toString(),
      productId: map['productId']?.toString(),
      orderId: map['orderId']?.toString(),
      addressLabel: map['addressLabel']?.toString(),
      assignedAdminUid: map['assignedAdminUid']?.toString(),
      assignedAdminEmail: map['assignedAdminEmail']?.toString(),
      assignedAdminName: map['assignedAdminName']?.toString(),
      assignedAdminDistanceKm:
          (map['assignedAdminDistanceKm'] as num?)?.toDouble(),
      assignedAdminState: map['assignedAdminState']?.toString(),
      assignedAdminArea: map['assignedAdminArea']?.toString(),
      assignmentMethod: map['assignmentMethod']?.toString(),
      activeAdminLoad: (map['activeAdminLoad'] as num?)?.toInt(),
      escalatedToSuperAdmin:
          (map['escalatedToSuperAdmin'] ?? false) == true,
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'userId': userId,
      'pickup': pickup,
      'destination': destination,
      'rideType': rideType,
      'status': status,
      'driver': driver,
      'price': price,
      'note': note,
      'eta': eta,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'routeGeometry': routeGeometry,
      'productId': productId,
      'orderId': orderId,
      'addressLabel': addressLabel,
      'assignedAdminUid': assignedAdminUid,
      'assignedAdminEmail': assignedAdminEmail,
      'assignedAdminName': assignedAdminName,
      'assignedAdminDistanceKm': assignedAdminDistanceKm,
      'assignedAdminState': assignedAdminState,
      'assignedAdminArea': assignedAdminArea,
      'assignmentMethod': assignmentMethod,
      'activeAdminLoad': activeAdminLoad,
      'escalatedToSuperAdmin': escalatedToSuperAdmin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RideModel copyWith({
    String? id,
    String? type,
    String? userId,
    String? pickup,
    String? destination,
    String? rideType,
    String? status,
    String? driver,
    double? price,
    String? note,
    String? eta,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    double? driverLat,
    double? driverLng,
    double? distanceKm,
    double? durationMin,
    String? routeGeometry,
    String? productId,
    String? orderId,
    String? addressLabel,
    String? assignedAdminUid,
    String? assignedAdminEmail,
    String? assignedAdminName,
    double? assignedAdminDistanceKm,
    String? assignedAdminState,
    String? assignedAdminArea,
    String? assignmentMethod,
    int? activeAdminLoad,
    bool? escalatedToSuperAdmin,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      rideType: rideType ?? this.rideType,
      status: status ?? this.status,
      driver: driver ?? this.driver,
      price: price ?? this.price,
      note: note ?? this.note,
      eta: eta ?? this.eta,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMin: durationMin ?? this.durationMin,
      routeGeometry: routeGeometry ?? this.routeGeometry,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      addressLabel: addressLabel ?? this.addressLabel,
      assignedAdminUid: assignedAdminUid ?? this.assignedAdminUid,
      assignedAdminEmail:
          assignedAdminEmail ?? this.assignedAdminEmail,
      assignedAdminName:
          assignedAdminName ?? this.assignedAdminName,
      assignedAdminDistanceKm:
          assignedAdminDistanceKm ?? this.assignedAdminDistanceKm,
      assignedAdminState:
          assignedAdminState ?? this.assignedAdminState,
      assignedAdminArea:
          assignedAdminArea ?? this.assignedAdminArea,
      assignmentMethod: assignmentMethod ?? this.assignmentMethod,
      activeAdminLoad: activeAdminLoad ?? this.activeAdminLoad,
      escalatedToSuperAdmin:
          escalatedToSuperAdmin ?? this.escalatedToSuperAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
