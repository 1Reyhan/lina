import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid; // ref -> users
  final List<String> allergies;
  final List<String> dietTypes;
  final List<String> healthConditions;
  final int portionSize;
  final List<Map<String, dynamic>> addresses;
  final String defaultAddressId;
  final int loyaltyPoints;
  final bool smartReplenishEnabled;
  final DateTime updatedAt;

  UserProfileModel({
    required this.uid,
    this.allergies = const [],
    this.dietTypes = const [],
    this.healthConditions = const [],
    this.portionSize = 2,
    this.addresses = const [],
    this.defaultAddressId = '',
    this.loyaltyPoints = 0,
    this.smartReplenishEnabled = false,
    required this.updatedAt,
  });

  // BURAYA EKLENDİ: Firestore'dan gelen veriyi modele çevirir
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfileModel(
      uid: doc.id,
      allergies: List<String>.from(d['allergies'] ?? []),
      dietTypes: List<String>.from(d['dietTypes'] ?? []),
      healthConditions: List<String>.from(d['healthConditions'] ?? []),
      portionSize: d['portionSize'] ?? 2,
      addresses: List<Map<String, dynamic>>.from(d['addresses'] ?? []),
      defaultAddressId: d['defaultAddressId'] ?? '',
      loyaltyPoints: d['loyaltyPoints'] ?? 0,
      smartReplenishEnabled: d['smartReplenishEnabled'] ?? false,
      updatedAt: (d['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'allergies': allergies,
      'dietTypes': dietTypes,
      'healthConditions': healthConditions,
      'portionSize': portionSize,
      'addresses': addresses,
      'defaultAddressId': defaultAddressId,
      'loyaltyPoints': loyaltyPoints,
      'smartReplenishEnabled': smartReplenishEnabled,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
