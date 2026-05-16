import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String campaignId;
  final String sellerId;
  final String title;
  final String
  type; // 'discount' | 'bundle' | 'replenish' | 'lost_user' (Kağıttaki tüm enumlar eklendi)
  final String targetSegment; // 'all' | 'new' | 'loyal' | 'lost'
  final double discountRate;
  final List<String> productIds;
  final bool aiGenerated;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  CampaignModel({
    required this.campaignId,
    required this.sellerId,
    required this.title,
    required this.type,
    this.targetSegment = 'all',
    required this.discountRate,
    this.productIds = const [],
    this.aiGenerated = false,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {}; // Null harita koruması

    // Güvenli Timestamp dönüşümleri
    final startTimestamp = d['startDate'] as Timestamp?;
    final endTimestamp = d['endDate'] as Timestamp?;

    return CampaignModel(
      campaignId: doc.id,
      sellerId: d['sellerId'] ?? '',
      title: d['title'] ?? '',
      type: d['type'] ?? 'discount',
      targetSegment: d['targetSegment'] ?? 'all',
      discountRate: (d['discountRate'] ?? 0).toDouble(),
      productIds: List<String>.from(d['productIds'] ?? []),
      aiGenerated: d['aiGenerated'] ?? false,
      startDate:
          startTimestamp != null ? startTimestamp.toDate() : DateTime.now(),
      endDate:
          endTimestamp != null
              ? endTimestamp.toDate()
              : DateTime.now().add(const Duration(days: 7)),
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'sellerId': sellerId,
    'title': title,
    'type': type,
    'targetSegment': targetSegment,
    'discountRate': discountRate,
    'productIds': productIds,
    'aiGenerated': aiGenerated,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isActive': isActive,
  };
}
