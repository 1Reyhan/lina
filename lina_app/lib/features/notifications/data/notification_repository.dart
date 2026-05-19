import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lina/shared/models/notification_model.dart'; // Proje isminize uygun tam import yolu

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının kendi bildirimlerini stream olarak dinler.
  /// Riverpod içinde bu repository'i kullanarak state yönetimi yapabilirsiniz.
  Stream<List<NotificationModel>> getMyNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Bir bildirimi okundu olarak işaretler.
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Yeni bildirim oluşturma (Sistem tarafından tetiklenir).
  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }
}
