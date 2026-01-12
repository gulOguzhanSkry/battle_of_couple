import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/ai_constants.dart';
import '../models/exam_report_model.dart';
import '../models/ai_exam_report_service.dart';
import '../models/ai_exam_report_mixin.dart';

/// Google Gemini API üzerinden sınav raporu üretme servisi.
/// [AIExamReportService] interface'ini implemente eder.
class GeminiReportService extends AIExamReportService with AIExamReportMixin {
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  
  GenerativeModel? _model;

  @override
  String get providerName => 'Gemini';

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Lazy initialization için model getter
  GenerativeModel get _generativeModel {
    _model ??= GenerativeModel(
      model: AIConstants.geminiModel,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    return _model!;
  }

  @override
  Future<ExamReport> generateExamReport({
    required List<WrongAnswerData> wrongAnswers,
    required String categoryId,
    required int totalQuestions,
    required int correctCount,
  }) async {
    // Tüm sorular doğruysa özel rapor döndür
    if (wrongAnswers.isEmpty) {
      return ExamReport.perfect(totalQuestions: totalQuestions);
    }

    _validateConfiguration();

    try {
      final prompt = buildReportPrompt(
        wrongAnswers: wrongAnswers,
        categoryId: categoryId,
        totalQuestions: totalQuestions,
        correctCount: correctCount,
      );

      debugPrint('[$providerName] Generating exam report...');
      final response = await _sendRequest(prompt);
      
      return parseReportFromJson(
        response,
        totalQuestions: totalQuestions,
        correctCount: correctCount,
        wrongCount: wrongAnswers.length,
      );
    } catch (e) {
      logReportError('generateExamReport', e);
      rethrow;
    }
  }

  /// API key'in mevcut olduğunu doğrular
  void _validateConfiguration() {
    if (!isConfigured) {
      throw Exception('Gemini API Key bulunamadı. .env dosyasında GEMINI_API_KEY tanımlayın.');
    }
  }

  /// Gemini API'ye istek gönderir
  Future<String> _sendRequest(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _generativeModel
          .generateContent(content)
          .timeout(AIConstants.requestTimeout);

      if (response.text == null) {
        throw Exception('Gemini API boş yanıt döndürdü.');
      }

      return response.text!;
    } catch (e) {
      debugPrint('[$providerName] API request error: $e');
      rethrow;
    }
  }
}
