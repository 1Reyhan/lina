import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String uid; // ref -> users
  final String storeName; // Mağaza Adı
  final String logoURL; // Logo Bağlantısı
  final String bannerURL; // Mağaza Kapak Görseli
  final String description; // Mağaza Açıklaması
  final String city; // Şehir
  final String district; // İlçe
  final GeoPoint? geoPoint; // Konum Koordinatları
  final double rating; // Mağaza Puanı 0-5
  final int reviewCount; // Değerlendirme Sayısı
  final int totalSales; // Toplam Satış Sayısı
  final bool isApproved; // Onaylı Satıcı mı?
  final bool isOpen; // Mağaza Şu An Açık mı?
  final String bankIBAN; // Şifrelenmiş IBAN
  final DateTime createdAt; // Kayıt Tarihi

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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
