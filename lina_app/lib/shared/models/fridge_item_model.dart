import 'package:cloud_firestore/cloud_firestore.dart';

class FridgeItemModel {
  final String id;
  final String uid;
  final String productId;
  final String name;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final DateTime addedAt;
  final String addedFrom; // 'order' | 'manual' | 'barcode'
  final bool isConsumed;

  FridgeItemModel({
    required this.id,
    required this.uid,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.addedAt,
    this.addedFrom = 'manual',
    this.isConsumed = false,
  });

  // 🌟 DÜZELTİLDİ: Saat farkından dolayı erken "Tarihi Geçti" uyarısı vermemesi için sadece gün karşılaştırması yapar
  bool get isExpiringSoon {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final diff = expiry.difference(today).inDays;
    return diff <= 3 && diff >= 0;
  }

  // 🌟 DÜZELTİLDİ: Saat farkı tuzağından arındırılmış tam gün kontrolü
  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isBefore(today);
  }

  // 🌟 YENİ: Buzdolabındaki ürün miktarını güncellerken (örn: sütü içtikçe miktar azaltma) işleri kolaylaştırır
  FridgeItemModel copyWith({
    String? id,
    String? uid,
    String? productId,
    String? name,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? addedAt,
    String? addedFrom,
    bool? isConsumed,
  }) {
    return FridgeItemModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
      addedFrom: addedFrom ?? this.addedFrom,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }

  factory FridgeItemModel.fromFirestore(DocumentSnapshot doc) {
    // 🌟 DÜZELTİLDİ: Null döküman crash koruması eklendi
    final d = doc.data() as Map<String, dynamic>? ?? {};

    // Güvenli tarih dönüşümleri
    final expiryTimestamp = d['expiryDate'] as Timestamp?;
    final addedAtTimestamp = d['addedAt'] as Timestamp?;

    return FridgeItemModel(
      id: doc.id,
      uid: d['uid'] ?? '',
      productId: d['productId'] ?? '',
      name: d['name'] ?? '',
      quantity: (d['quantity'] ?? 0).toDouble(),
      unit: d['unit'] ?? 'adet',
      expiryDate:
          expiryTimestamp != null ? expiryTimestamp.toDate() : DateTime.now(),
      addedAt:
          addedAtTimestamp != null ? addedAtTimestamp.toDate() : DateTime.now(),
      addedFrom: d['addedFrom'] ?? 'manual',
      isConsumed: d['isConsumed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'expiryDate': Timestamp.fromDate(expiryDate),
    'addedAt': Timestamp.fromDate(addedAt),
    'addedFrom': addedFrom,
    'isConsumed': isConsumed,
  };
}
