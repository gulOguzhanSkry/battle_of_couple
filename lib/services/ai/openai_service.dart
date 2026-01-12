import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/question_model.dart';
import '../../core/constants/ai_constants.dart';
import 'ai_question_service.dart';
import 'ai_question_mixin.dart';
import 'ai_service_exception.dart';

/// OpenAI GPT API üzerinden soru üretme servisi.
/// [AIQuestionService] interface'ini implemente eder.
class OpenAIService extends AIQuestionService with AIQuestionMixin {
  static final String? _apiKey = dotenv.env['OPENAI_API_KEY'];

  @override
  String get providerName => 'OpenAI';

  @override
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  Future<List<QuestionModel>> generateQuestions({
    required String categoryId,
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    required String userId,
    String? style,
  }) async {
    _validateConfiguration();

    final prompt = buildQuestionPrompt(
      categoryId: categoryId,
      subCategory: subCategory,
      topic: topic,
      difficulty: difficulty,
      count: count,
      style: style,
    );

    try {
      final response = await _sendRequest(prompt);
      
      return parseQuestionsFromJson(
        response,
        categoryId: categoryId,
        subCategory: subCategory,
        difficulty: difficulty,
        userId: userId,
      );
    } catch (e) {
      logError('generateQuestions', e);
      rethrow;
    }
  }

  /// API key'in mevcut olduğunu doğrular
  void _validateConfiguration() {
    if (!isConfigured) {
      throw AIServiceException(
        provider: providerName,
        message: 'API Key bulunamadı. .env dosyasında OPENAI_API_KEY tanımlayın.',
      );
    }
  }

  /// OpenAI API'ye istek gönderir
  Future<String> _sendRequest(String prompt) async {
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
            'content': AIConstants.systemPromptJson
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    ).timeout(AIConstants.requestTimeout);

    if (response.statusCode != 200) {
      throw AIServiceException(
        provider: providerName,
        message: 'API isteği başarısız (${response.statusCode})',
        details: response.body,
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices']?[0]?['message']?['content'];

    if (content == null) {
      throw AIServiceException(
        provider: providerName,
        message: 'API boş yanıt döndürdü.',
      );
    }

    return content.toString();
  }
}
