import 'dart:convert'; // 🌟 DÜZELTİLDİ: jsonDecode işlemleri için standart kütüphane eklendi
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRepository {
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiRepository() {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
    _visionModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
  }

  // ── 1. Serbest sohbet / asistan ──
  Future<String> chat(String message, {String? systemContext}) async {
    try {
      final prompt =
          systemContext != null
              ? '$systemContext\n\nKullanıcı: $message'
              : message;
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Yanıt alınamadı.';
    } catch (e) {
      return 'Hata oluştu: $e';
    }
  }

  // ── 2. Görsel analiz — yemek fotoğrafından malzeme listesi ──
  Future<List<String>> analyzeRecipeImage(Uint8List imageBytes) async {
    try {
      final prompt = '''
Bu yemek fotoğrafına bak. İçindeki malzemeleri listele.
SADECE JSON formatında döndür, başka hiçbir şey yazma:
{"ingredients": ["malzeme1", "malzeme2", "malzeme3"]}
''';
      final response = await _visionModel.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);
      final text = response.text ?? '{"ingredients":[]}';

      // 🌟 DÜZELTİLDİ: Manuel regex temizleme yerine güvenli JSON çözümlemesi
      final parsed = _parseJson(text);
      final ingredients = parsed['ingredients'];
      if (ingredients is List) {
        return ingredients.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Lina AI Error (analyzeRecipeImage): $e');
      return [];
    }
  }

  // ── 3. Ürün paketi/etiketi analizi — satıcı için ──
  Future<Map<String, dynamic>> analyzeProductLabel(Uint8List imageBytes) async {
    try {
      final prompt = '''
Bu ürün etiketini veya paketini analiz et.
SADECE JSON formatında döndür:
{
  "name": "ürün adı",
  "category": "kategori",
  "ingredients": ["içerik1", "içerik2"],
  "allergens": ["alerjen1"],
  "calories": 0,
  "weight": "miktar",
  "description": "SEO uyumlu açıklama"
}
''';
      final response = await _visionModel.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);
      final text = response.text ?? '{}';
      return _parseJson(text);
    } catch (e) {
      print('Lina AI Error (analyzeProductLabel): $e');
      return {};
    }
  }

  // ── 4. Tarif kişiselleştirme ──
  Future<String> personalizeRecipe({
    required String recipeName,
    required List<String> allergies,
    required List<String> dietTypes,
    required List<String> healthConditions,
    required int portions,
  }) async {
    try {
      final prompt = '''
Kullanıcı profili:
- Alerjiler: ${allergies.isEmpty ? 'yok' : allergies.join(', ')}
- Diyet: ${dietTypes.isEmpty ? 'yok' : dietTypes.join(', ')}
- Sağlık durumu: ${healthConditions.isEmpty ? 'yok' : healthConditions.join(', ')}
- Kişi sayısı: $portions

"$recipeName" tarifini bu profile göre düzenle.
Türkçe yaz. Malzemeleri ve adımları listele.
Önemli değişiklikleri belirt (örn: "gluten içeren un yerine pirinç unu kullandım").
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tarif oluşturulamadı.';
    } catch (e) {
      return 'Hata: $e';
    }
  }

  // ── 5. Buzdolabı önerisi ──
  Future<String> suggestFromFridge(List<String> availableItems) async {
    try {
      final prompt = '''
Buzdolabında şu malzemeler var: ${availableItems.join(', ')}.
Bu malzemelerle yapılabilecek 3 yemek öner.
Türkçe, kısa ve pratik yaz.
Her öneri için: yemek adı ve neden bu malzemelerin uygun olduğunu söyle.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Öneri oluşturulamadı.';
    } catch (e) {
      return 'Hata: $e';
    }
  }

  // ── 6. Barkod / ürün sağlık analizi ──
  Future<String> analyzeProductHealth({
    required String productName,
    required List<String> ingredients,
    required List<String> userAllergies,
  }) async {
    try {
      final prompt = '''
Ürün: $productName
İçindekiler: ${ingredients.join(', ')}
Kullanıcı alerjileri: ${userAllergies.isEmpty ? 'yok' : userAllergies.join(', ')}

Bu ürünü analiz et:
1. Alerjen uyarısı var mı? (KIRMIZI/YEŞİL)
2. Karmaşık kimyasalları çocuğun anlayacağı dilde açıkla
3. Genel sağlık puanı ver (1-10)
Türkçe, kısa ve anlaşılır yaz.
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Analiz yapılamadı.';
    } catch (e) {
      return 'Hata: $e';
    }
  }

  // 🌟 YENİ: Gemini'ın bazen markdown kod bloklarıyla sardığı JSON metnini temizleyen yardımcı metot
  String _cleanMarkdownJson(String text) {
    var clean = text.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }

  // 🌟 DÜZELTİLDİ: 'import_dart_convert' etiket hatasını kaldıran güvenli ve yedekli JSON dönüştürücü
  Map<String, dynamic> _parseJson(String text) {
    try {
      final cleaned = _cleanMarkdownJson(text);
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      print(
        'Lina AI: JSON ayrıştırılamadı, alternatif ayıklama devrede. Hata: $e',
      );
      try {
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start != -1 && end != -1) {
          final jsonStr = text.substring(start, end + 1);
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      } catch (_) {}
      return {};
    }
  }
}
