import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRepository {
  late final String _apiKey;

  // 🌟 2026 standartlarına uygun en güncel ve kararlı model listesi
  final List<String> _modelCandidates = [
    'gemini-1.5-flash-latest', // En kararlı son güncel 1.5 sürümü
    'gemini-2.5-flash', // Yeni nesil yüksek performanslı flash modeli
    'gemini-1.5-flash', // Eski standart model (yedek)
    'gemini-1.5-pro', // Gelişmiş pro modeli (nihai yedek)
  ];

  GeminiRepository() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Belirtilen model ismiyle dinamik olarak GenerativeModel nesnesi oluşturur
  GenerativeModel _createModel(String modelName) {
    return GenerativeModel(model: modelName, apiKey: _apiKey);
  }

  // ── 1. Serbest sohbet / asistan (Görsel ve Metin Bir Arada Destekler!) ──
  Future<String> chat(
    String message, {
    String? systemContext,
    Uint8List? imageBytes,
  }) async {
    final prompt =
        systemContext != null
            ? '$systemContext\n\nKullanıcı: $message'
            : message;

    // Modelleri sırayla dener, çalışan ilk modeli kullanır
    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        GenerateContentResponse response;

        if (imageBytes != null) {
          // Eğer görsel varsa, çoklu ortam (multimodal) isteği gönderilir
          response = await model.generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ]),
          ]);
        } else {
          // Sadece metin varsa standart istek gönderilir
          response = await model.generateContent([Content.text(prompt)]);
        }

        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        // Hata konsola basılır ama kullanıcıya hissettirilmeden bir sonraki model denenir
        print(
          'Lina AI: $modelName başarısız oldu, sonraki model deneniyor. Hata: $e',
        );
      }
    }
    return 'Üzgünüm, şu anda Lina AI sunucularına bağlanılamıyor. Lütfen internet bağlantınızı veya API anahtarınızı kontrol edin.';
  }

  // ── 2. Görsel analiz — yemek fotoğrafından malzeme listesi (Yedekli Çalışır) ──
  Future<List<String>> analyzeRecipeImage(Uint8List imageBytes) async {
    final prompt = '''
Bu yemek fotoğrafına bak. İçindeki malzemeleri listele.
SADECE JSON formatında döndür, başka hiçbir şey yazma:
{"ingredients": ["malzeme1", "malzeme2", "malzeme3"]}
''';

    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ]);

        final text = response.text ?? '{"ingredients":[]}';
        final parsed = _parseJson(text);
        final ingredients = parsed['ingredients'];
        if (ingredients is List) {
          return ingredients.map((e) => e.toString()).toList();
        }
      } catch (e) {
        print(
          'Lina AI: $modelName görsel analizi başaramadı, sıradaki deneniyor. Hata: $e',
        );
      }
    }
    return [];
  }

  // ── 3. Ürün paketi/etiketi analizi — satıcı için (Yedekli Çalışır) ──
  Future<Map<String, dynamic>> analyzeProductLabel(Uint8List imageBytes) async {
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

    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ]);
        final text = response.text ?? '{}';
        return _parseJson(text);
      } catch (e) {
        print(
          'Lina AI: $modelName etiket analizi başaramadı, sıradaki deneniyor. Hata: $e',
        );
      }
    }
    return {};
  }

  // ── 4. Tarif kişiselleştirme ──
  Future<String> personalizeRecipe({
    required String recipeName,
    required List<String> allergies,
    required List<String> dietTypes,
    required List<String> healthConditions,
    required int portions,
  }) async {
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

    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null) return response.text!;
      } catch (e) {
        print('Lina AI: $modelName tarif kişiselleştirme hatası: $e');
      }
    }
    return 'Tarif özelleştirilemedi.';
  }

  // ── 5. Buzdolabı önerisi ──
  Future<String> suggestFromFridge(List<String> availableItems) async {
    final prompt = '''
Buzdolabında şu malzemeler var: ${availableItems.join(', ')}.
Bu malzemelerle yapılabilecek 3 yemek öner.
Türkçe, kısa ve pratik yaz.
Her öneri için: yemek adı ve neden bu malzemelerin uygun olduğunu söyle.
''';

    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null) return response.text!;
      } catch (e) {
        print('Lina AI: $modelName dolap öneri hatası: $e');
      }
    }
    return 'Öneri oluşturulamadı.';
  }

  // ── 6. Barkod / ürün sağlık analizi ──
  Future<String> analyzeProductHealth({
    required String productName,
    required List<String> ingredients,
    required List<String> userAllergies,
  }) async {
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

    for (String modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null) return response.text!;
      } catch (e) {
        print('Lina AI: $modelName sağlık analizi hatası: $e');
      }
    }
    return 'Analiz yapılamadı.';
  }

  // 🌟 Markdown kod bloklarıyla sardığı JSON metnini temizleyen yardımcı metot
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

  // 🌟 Güvenli ve yedekli JSON dönüştürücü
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
