import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String uid;
  final String storeName;
  final String logoURL;
  final String bannerURL;
  final String description;
  final String city;
  final String district;
  final GeoPoint? geoPoint;
  final double rating;
  final int reviewCount;
  final int totalSales;
  final bool isApproved;
  final bool isOpen;
  final String bankIBAN;
  final String sellerType; // 'bireysel_üretici' | 'yerel_market' | 'kurumsal'
  final DateTime createdAt;

  SellerModel({
    required this.uid,
    required this.storeName,
    this.logoURL = '',
    this.bannerURL = '',
    this.description = '',
    required this.city,
    required this.district,
    this.geoPoint,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalSales = 0,
    this.isApproved = false,
    this.isOpen = true,
    this.bankIBAN = '',
    required this.sellerType,
    required this.createdAt,
  });

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerModel(
      uid: doc.id,
      storeName: data['storeName'] ?? '',
      logoURL: data['logoURL'] ?? '',
      bannerURL: data['bannerURL'] ?? '',
      description: data['description'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      geoPoint: data['geoPoint'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      totalSales: data['totalSales'] ?? 0,
      isApproved: data['isApproved'] ?? false,
      isOpen: data['isOpen'] ?? true,
      bankIBAN: data['bankIBAN'] ?? '',
      sellerType: data['sellerType'] ?? 'bireysel_üretici',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'storeName': storeName,
      'logoURL': logoURL,
      'bannerURL': bannerURL,
      'description': description,
      'city': city,
      'district': district,
      'geoPoint': geoPoint,
      'rating': rating,
      'reviewCount': reviewCount,
      'totalSales': totalSales,
      'isApproved': isApproved,
      'isOpen': isOpen,
      'bankIBAN': bankIBAN,
      'sellerType': sellerType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
