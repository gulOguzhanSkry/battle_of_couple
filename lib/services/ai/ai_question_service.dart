import '../../models/question_model.dart';

/// AI soru üretme servisleri için abstract interface.
/// OpenAI, Gemini veya başka AI servisleri bu interface'i implement eder.
/// 
/// Kategori Hiyerarşisi:
/// categoryId (zorunlu) → subCategory (opsiyonel) → topic (opsiyonel)
abstract class AIQuestionService {
  /// Servis sağlayıcı adı (debugging ve logging için)
  String get providerName;
  
  /// API anahtarının mevcut olup olmadığını kontrol eder
  bool get isConfigured;
  
  /// Belirtilen kriterlere göre quiz soruları üretir
  /// 
  /// [categoryId] - Ana kategori ID'si (örn: "kpss", "tus", "ayt") - ZORUNLU
  /// [subCategory] - Alt kategori (örn: "Tarih", "Biyoloji") - opsiyonel
  /// [topic] - Konu başlığı (örn: "Osmanlı Kuruluş Dönemi") - opsiyonel
  /// [difficulty] - Zorluk seviyesi ("easy", "medium", "hard")
  /// [count] - Üretilecek soru sayısı
  /// [userId] - Soruyu oluşturan kullanıcı ID'si
  Future<List<QuestionModel>> generateQuestions({
    required String categoryId,
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    required String userId,
    String? style,
  });
}
