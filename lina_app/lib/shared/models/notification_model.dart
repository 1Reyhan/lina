import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String toUid; // Kullanıcı ile ilişkilendirme alanı
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.toUid,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      toUid: data['toUid'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toUid': toUid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
