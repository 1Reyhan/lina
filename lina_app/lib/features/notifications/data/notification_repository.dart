import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının bildirimlerini gerçek zamanlı izler
  Stream<List<Map<String, dynamic>>> watchNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {'id': doc.id, ...data};
              }).toList(),
        );
  }

  /// Bir bildirimi okundu olarak işaretler
  Future<void> markRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Hata yönetimi burada eklenebilir
      throw Exception('Bildirim güncellenemedi: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretler
  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final snapshot =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
