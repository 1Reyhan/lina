import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/seller_model.dart';
import '../../../shared/models/user_profile_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Anlık kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore'dan rol oku
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'];
  }

  // Müşteri Kaydı
  Future<void> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 1. users tablosuna yaz
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: 'user',
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(user.toMap());

    // 2. userProfiles tablosuna yaz (Model kullanımı ile temizlendi)
    final userProfile = UserProfileModel(uid: uid, updatedAt: DateTime.now());
    await _db.collection('userProfiles').doc(uid).set(userProfile.toMap());
  }

  // Satıcı Kaydı
  Future<void> registerSeller({
    required String email,
    required String password,
    required String displayName,
    required String storeName,
    required String city,
    required String district,
    required String
    sellerType, // 'bireysel_üretici' | 'yerel_market' | 'kurumsal'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 1. users tablosuna yaz
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: 'seller',
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(user.toMap());

    // 2. sellers tablosuna yaz (GÜNCELLENDİ: sellerType artık modelin içinde)
    final seller = SellerModel(
      uid: uid,
      storeName: storeName,
      city: city,
      district: district,
      sellerType: sellerType, // Artık doğrudan model içinde tanımlıyoruz
      createdAt: DateTime.now(),
    );

    // sellerData oluşturup manuel müdahale etmeye gerek kalmadı
    await _db.collection('sellers').doc(uid).set(seller.toMap());
  }

  // Giriş
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Çıkış
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
