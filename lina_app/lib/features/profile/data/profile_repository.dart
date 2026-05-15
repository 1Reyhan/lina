import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_profile_model.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  // 1. Profil Verisini Getir (Model olarak döndürür)
  Future<UserProfileModel?> getProfile(String uid) async {
    try {
      final doc = await _db.collection('userProfiles').doc(uid).get();
      if (!doc.exists) return null;

      return UserProfileModel.fromFirestore(doc);
    } catch (e) {
      print("Profil getirme hatası: $e");
      return null;
    }
  }

  // 2. Profili Güncelle (Alerji, Diyet vb. değişiklikler için)
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('userProfiles').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(), // Şemadaki updatedAt alanı
    });
  }

  // 3. Yeni Adres Ekle (Şemadaki addresses array yapısına uygun)
  Future<void> addAddress(String uid, Map<String, dynamic> address) async {
    await _db.collection('userProfiles').doc(uid).update({
      'addresses': FieldValue.arrayUnion([address]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Varsayılan Adresi Değiştir (Şemadaki defaultAddressId alanı)
  Future<void> setDefaultAddress(String uid, String addressId) async {
    await _db.collection('userProfiles').doc(uid).update({
      'defaultAddressId': addressId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 5. Sadakat Puanı Güncelle (Şemadaki loyaltyPoints alanı)
  Future<void> updateLoyaltyPoints(String uid, int points) async {
    await _db.collection('userProfiles').doc(uid).update({
      'loyaltyPoints': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
