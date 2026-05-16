import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String sellerId;
  final List<CartItemModel> items;
  final String
  status; // 'pending'|'confirmed'|'preparing'|'shipped'|'delivered'|'cancelled'
  final Map<String, dynamic> deliveryAddress;
  final double totalAmount;
  final double discountAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String couponCode;
  final String deliveryNote;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.items,
    this.status = 'pending',
    required this.deliveryAddress,
    required this.totalAmount,
    this.discountAmount = 0,
    this.paymentMethod = 'kapıda_ödeme',
    this.paymentStatus = 'pending',
    this.couponCode = '',
    this.deliveryNote = '',
    this.estimatedDelivery,
    required this.createdAt,
    required this.updatedAt,
  });

  double get effectivePrice => totalAmount - discountAmount;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    // Güvenli sepet öğeleri haritalaması
    List<CartItemModel> parsedItems = [];
    if (d['items'] != null && d['items'] is List) {
      try {
        parsedItems =
            (d['items'] as List<dynamic>).map((e) {
              return CartItemModel.fromMap(Map<String, dynamic>.from(e as Map));
            }).toList();
      } catch (e) {
        print('faz3: Sipariş ürünleri ayrıştırılırken hata: $e');
      }
    }

    // Güvenli zaman damgası dönüşümleri
    final createdAtTimestamp = d['createdAt'] as Timestamp?;
    final updatedAtTimestamp = d['updatedAt'] as Timestamp?;
    final estimatedDeliveryTimestamp = d['estimatedDelivery'] as Timestamp?;

    return OrderModel(
      orderId: doc.id,
      userId: d['userId'] ?? '',
      sellerId: d['sellerId'] ?? '',
      items: parsedItems,
      status: d['status'] ?? 'pending',
      deliveryAddress: Map<String, dynamic>.from(d['deliveryAddress'] ?? {}),
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
      discountAmount: (d['discountAmount'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? 'kapıda_ödeme',
      paymentStatus: d['paymentStatus'] ?? 'pending',
      couponCode: d['couponCode'] ?? '',
      deliveryNote: d['deliveryNote'] ?? '',
      estimatedDelivery: estimatedDeliveryTimestamp?.toDate(),
      createdAt:
          createdAtTimestamp != null
              ? createdAtTimestamp.toDate()
              : DateTime.now(),
      updatedAt:
          updatedAtTimestamp != null
              ? updatedAtTimestamp.toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'sellerId': sellerId,
    'items': items.map((e) => e.toMap()).toList(),
    'status': status,
    'deliveryAddress': deliveryAddress,
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'couponCode': couponCode,
    'deliveryNote': deliveryNote,
    'estimatedDelivery':
        estimatedDelivery != null
            ? Timestamp.fromDate(estimatedDelivery!)
            : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt':
        FieldValue.serverTimestamp(), // Güncelleme anında sunucu saatini tetikler
  };
}
