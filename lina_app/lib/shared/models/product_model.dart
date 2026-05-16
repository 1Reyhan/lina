import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String sellerId;
  final String name;
  final String description;
  final List<String> images;
  final String barcode;
  final String category;
  final String subCategory;
  final double price;
  final double discountPrice;
  final String unit; // 'kg' | 'g' | 'adet' | 'lt'
  final double weight;
  final int stock;
  final int calories;
  final List<String> allergens;
  final List<String> ingredients;
  final double healthScore;
  final double carbonScore;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.name,
    this.description = '',
    this.images = const [],
    this.barcode = '',
    required this.category,
    this.subCategory = '',
    required this.price,
    this.discountPrice = 0,
    this.unit = 'adet',
    this.weight = 0,
    this.stock = 0,
    this.calories = 0,
    this.allergens = const [],
    this.ingredients = const [],
    this.healthScore = 0,
    this.carbonScore = 0,
    this.isActive = true,
    required this.createdAt,
  });

  double get effectivePrice => discountPrice > 0 ? discountPrice : price;

  bool get hasDiscount => discountPrice > 0 && discountPrice < price;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    // Güvenli zaman damgası dönüşümü
    final createdAtTimestamp = d['createdAt'] as Timestamp?;
    final parsedDate =
        createdAtTimestamp != null
            ? createdAtTimestamp.toDate()
            : DateTime.now();

    return ProductModel(
      productId: doc.id,
      sellerId: d['sellerId'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      images: List<String>.from(d['images'] ?? []),
      barcode: d['barcode'] ?? '',
      category: d['category'] ?? '',
      subCategory: d['subCategory'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      discountPrice: (d['discountPrice'] ?? 0).toDouble(),
      unit: d['unit'] ?? 'adet',
      weight: (d['weight'] ?? 0).toDouble(),
      stock: d['stock'] ?? 0,
      calories: d['calories'] ?? 0,
      allergens: List<String>.from(d['allergens'] ?? []),
      ingredients: List<String>.from(d['ingredients'] ?? []),
      healthScore: (d['healthScore'] ?? 0).toDouble(),
      carbonScore: (d['carbonScore'] ?? 0).toDouble(),
      isActive: d['isActive'] ?? true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'sellerId': sellerId,
    'name': name,
    'description': description,
    'images': images,
    'barcode': barcode,
    'category': category,
    'subCategory': subCategory,
    'price': price,
    'discountPrice': discountPrice,
    'unit': unit,
    'weight': weight,
    'stock': stock,
    'calories': calories,
    'allergens': allergens,
    'ingredients': ingredients,
    'healthScore': healthScore,
    'carbonScore': carbonScore,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
