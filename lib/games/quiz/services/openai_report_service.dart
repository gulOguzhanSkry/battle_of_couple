import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/ai_constants.dart';
import '../models/exam_report_model.dart';
import '../models/ai_exam_report_service.dart';
import '../models/ai_exam_report_mixin.dart';

/// OpenAI GPT API üzerinden sınav raporu üretme servisi.
/// [AIExamReportService] interface'ini implemente eder.
class OpenAIReportService extends AIExamReportService with AIExamReportMixin {
  static final String? _apiKey = dotenv.env['OPENAI_API_KEY'];

  @override
  String get providerName => 'OpenAI';

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

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
      throw Exception('OpenAI API Key bulunamadı. .env dosyasında OPENAI_API_KEY tanımlayın.');
    }
  }

  /// OpenAI API'ye istek gönderir
  Future<String> _sendRequest(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(AIConstants.openAIBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': AIConstants.openAIModel,
          'messages': [
            {
              'role': 'system',
              'content': 'Sen yardımcı bir eğitim asistanısın. Sadece JSON formatında yanıt ver.'
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      ).timeout(AIConstants.requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('OpenAI API isteği başarısız (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices']?[0]?['message']?['content'];

      if (content == null) {
        throw Exception('OpenAI API boş yanıt döndürdü.');
      }

      return content.toString();
    } catch (e) {
      debugPrint('[$providerName] API request error: $e');
      rethrow;
    }
  }
}
