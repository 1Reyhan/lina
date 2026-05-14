import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // Benzersiz Kimlik
  final String email; // E-posta
  final String displayName; // Görünen Ad
  final String photoURL; // Profil Fotoğrafı Bağlantısı
  final String role; // enum [user | seller | admin]
  final DateTime createdAt; // Oluşturulma Tarihi
  final bool isVerified; // Doğrulanmış Hesap mı?
  final bool isActive; // Hesap Aktif mi?
  final String languageCode; // Dil Tercihi
  final List<String> fcmTokens; // Bildirim Kimlikleri

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    required this.role,
    required this.createdAt,
    this.isVerified = false,
    this.isActive = true,
    this.languageCode = 'tr',
    this.fcmTokens = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      languageCode: data['languageCode'] ?? 'tr',
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'isActive': isActive,
      'languageCode': languageCode,
      'fcmTokens': fcmTokens,
    };
  }
}
