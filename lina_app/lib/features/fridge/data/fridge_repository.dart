import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/fridge_item_model.dart';

class FridgeRepository {
  final _db = FirebaseFirestore.instance;

  /// Kullanıcının buzdolabı öğelerini izler.
  /// RULE 2 Gereği: Firestore indeksleme hatalarından kaçınmak için
  /// sorguyu basitleştirdik, filtreleme işlemlerini uygulama tarafında (in-memory) yapıyoruz.
  Stream<List<FridgeItemModel>> watchFridgeItems(String uid) {
    return _db
        .collection('fridgeItems')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          // Önce verileri modele çevir
          final items =
              snap.docs.map((d) => FridgeItemModel.fromFirestore(d)).toList();

          // Şimdi bellekte filtrele (isConsumed == false olanlar)
          final activeItems = items.where((item) => !item.isConsumed).toList();

          // Şimdi bellekte sırala (tarihe göre)
          activeItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          return activeItems;
        });
  }

  /// Yeni öğe ekler. 'add' kullanımı doküman ID'sini otomatik oluşturur.
  Future<void> addItem(FridgeItemModel item) async {
    // Eğer Modelinizde 'id' alanı varsa, add işleminden sonra gelen
    // doküman ID'sini update ile kaydetmeniz gerekebilir.
    await _db.collection('fridgeItems').add(item.toMap());
  }

  /// Öğeyi tüketildi olarak işaretler.
  Future<void> markConsumed(String itemId) async {
    try {
      await _db.collection('fridgeItems').doc(itemId).update({
        'isConsumed': true,
      });
    } catch (e) {
      throw Exception('Tüketim işareti konulamadı: $e');
    }
  }

  /// Öğeyi tamamen siler.
  Future<void> deleteItem(String itemId) async {
    try {
      await _db.collection('fridgeItems').doc(itemId).delete();
    } catch (e) {
      throw Exception('Öğe silinemedi: $e');
    }
  }
}
