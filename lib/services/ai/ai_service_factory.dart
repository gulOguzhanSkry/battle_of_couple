import 'ai_question_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';

/// AI servis sağlayıcı türleri
enum AIProvider {
  openai,
  gemini,
}

/// AI servisleri için Factory pattern implementasyonu.
/// Kullanıcı tercihine göre uygun servisi döndürür.
class AIServiceFactory {
  static final Map<AIProvider, AIQuestionService> _instances = {};

  /// Singleton pattern - her provider için tek instance
  static AIQuestionService getService(AIProvider provider) {
    if (!_instances.containsKey(provider)) {
      _instances[provider] = _createService(provider);
    }
    return _instances[provider]!;
  }

  static AIQuestionService _createService(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIService();
      case AIProvider.gemini:
        return GeminiService();
    }
  }

  /// Mevcut ve yapılandırılmış ilk servisi döndürür
  /// Öncelik: OpenAI > Gemini (OpenAI daha stabil)
  static AIQuestionService? getAvailableService() {
    // Önce OpenAI'yı dene
    final openai = getService(AIProvider.openai);
    if (openai.isConfigured) return openai;

    // Sonra Gemini
    final gemini = getService(AIProvider.gemini);
    if (gemini.isConfigured) return gemini;

    return null;
  }

  /// Yapılandırılmış tüm servisleri listeler
  static List<AIQuestionService> getConfiguredServices() {
    return AIProvider.values
        .map((p) => getService(p))
        .where((s) => s.isConfigured)
        .toList();
  }

  /// Instance'ları temizle (test için)
  static void reset() {
    _instances.clear();
  }
}
