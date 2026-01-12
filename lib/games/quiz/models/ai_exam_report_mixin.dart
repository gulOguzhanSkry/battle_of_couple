import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'exam_report_model.dart';
import 'ai_exam_report_service.dart';

/// AI sınav raporu servisleri için ortak işlevsellik sağlayan mixin.
/// Prompt oluşturma ve JSON parsing mantığını merkezileştirir.
mixin AIExamReportMixin on AIExamReportService {
  
  /// Sınav raporu üretme promptunu oluşturur
  String buildReportPrompt({
    required List<WrongAnswerData> wrongAnswers,
    required String categoryId,
    required int totalQuestions,
    required int correctCount,
  }) {
    final wrongAnswersJson = wrongAnswers
        .map((a) => a.toJson())
        .toList();

    return '''
Sen bir eğitim uzmanısın. Öğrencinin bir sınavda yaptığı hataları analiz edeceksin.

SINAV BİLGİLERİ:
- Kategori: $categoryId
- Toplam Soru: $totalQuestions
- Doğru: $correctCount
- Yanlış: ${wrongAnswers.length}
- Başarı Oranı: %${((correctCount / totalQuestions) * 100).toStringAsFixed(1)}

YANLIŞ CEVAPLAR:
${jsonEncode(wrongAnswersJson)}

GÖREV:
1. Yanlış cevapları analiz et
2. Öğrencinin hangi konularda eksik olduğunu belirle
3. Her zayıf konu için kısa bir açıklama yaz
4. Genel bir değerlendirme yap
5. Somut çalışma önerileri sun

YANIT FORMATI (JSON):
{
  "weakTopics": [
    {
      "topicName": "Konu adı",
      "explanation": "Bu konuda şu kavramları anlamak önemli: ...",
      "wrongCount": 2,
      "relatedQuestions": ["Soru 1...", "Soru 2..."]
    }
  ],
  "overallAnalysis": "Genel değerlendirme metni...",
  "recommendations": [
    "Öneri 1",
    "Öneri 2",
    "Öneri 3"
  ]
}

ÖNEMLİ:
- Sadece JSON döndür, başka metin ekleme
- Türkçe yaz
- Yapıcı ve motive edici ol
- Konuları gruplayarak zayıf noktaları belirle
''';
  }

  /// AI yanıtından JSON'ı temizler
  String cleanJsonResponse(String response) {
    return response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  /// JSON'ı ExamReport'a dönüştürür
  ExamReport parseReportFromJson(
    String jsonString, {
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
  }) {
    try {
      final cleanJson = cleanJsonResponse(jsonString);
      final decoded = json.decode(cleanJson);
      
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
      }
      
      return ExamReport.fromJson(
        decoded,
        totalQuestions: totalQuestions,
        correctCount: correctCount,
        wrongCount: wrongCount,
      );
    } catch (e) {
      debugPrint('[$providerName] JSON parse error: $e');
      debugPrint('[$providerName] Raw response: $jsonString');
      rethrow;
    }
  }

  /// Hata loglama
  void logReportError(String message, dynamic error) {
    debugPrint('[$providerName] ExamReport $message: $error');
  }
}
