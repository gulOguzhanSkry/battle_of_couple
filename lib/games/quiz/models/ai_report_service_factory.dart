import 'ai_exam_report_service.dart';
import '../services/gemini_report_service.dart';
import '../services/openai_report_service.dart';

/// AI sınav raporu servisleri için Factory pattern.
/// Mevcut ve yapılandırılmış servisi döndürür.
class AIReportServiceFactory {
  static final Map<AIReportProvider, AIExamReportService> _instances = {};

  /// Singleton pattern - her provider için tek instance
  static AIExamReportService getService(AIReportProvider provider) {
    if (!_instances.containsKey(provider)) {
      _instances[provider] = _createService(provider);
    }
    return _instances[provider]!;
  }

  static AIExamReportService _createService(AIReportProvider provider) {
    switch (provider) {
      case AIReportProvider.openai:
        return OpenAIReportService();
      case AIReportProvider.gemini:
        return GeminiReportService();
    }
  }

  /// Mevcut ve yapılandırılmış ilk servisi döndürür
  /// Öncelik: OpenAI > Gemini (OpenAI daha stabil)
  static AIExamReportService? getAvailableService() {
    // Önce OpenAI'yı dene (daha stabil)
    final openai = getService(AIReportProvider.openai);
    if (openai.isConfigured) return openai;

    // Sonra Gemini
    final gemini = getService(AIReportProvider.gemini);
    if (gemini.isConfigured) return gemini;

    return null;
  }

  /// Yapılandırılmış tüm servisleri listeler
  static List<AIExamReportService> getConfiguredServices() {
    return AIReportProvider.values
        .map((p) => getService(p))
        .where((s) => s.isConfigured)
        .toList();
  }

  /// Instance'ları temizle (test için)
  static void reset() {
    _instances.clear();
  }
}

/// AI rapor sağlayıcı türleri
enum AIReportProvider {
  openai,
  gemini,
}
