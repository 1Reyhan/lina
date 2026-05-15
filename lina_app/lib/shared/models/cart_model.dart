import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String productId;
  final String sellerId;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.sellerId,
    required this.name,
    this.image = '',
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> d) => CartItemModel(
    productId: d['productId'] ?? '',
    sellerId: d['sellerId'] ?? '',
    name: d['name'] ?? '',
    image: d['image'] ?? '',
    price: (d['price'] ?? 0).toDouble(),
    quantity: d['quantity'] ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'sellerId': sellerId,
    'name': name,
    'image': image,
    'price': price,
    'quantity': quantity,
  };
}

class CartModel {
  final String uid;
  List<CartItemModel> items;
  final String? bundleId; // Opsiyonel paket kimliği eklendi
  final DateTime updatedAt;

  CartModel({
    required this.uid,
    this.items = const [],
    this.bundleId,
    required this.updatedAt,
  });

  double get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);

  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CartModel(
      uid: doc.id,
      bundleId: d['bundleId'], // Firestore'dan paket ID'sini okur
      items:
          (d['items'] as List<dynamic>? ?? [])
              .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
              .toList(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'items': items.map((e) => e.toMap()).toList(),
    'bundleId': bundleId, // Firestore'a paket ID'sini yazar
    'totalPrice': totalPrice,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
