import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lina/features/ai/data/gemini_repository.dart';

/// Gemini Repository'yi sağlayan sağlayıcı
final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepository();
});
