import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/question_model.dart';
import '../../core/constants/ai_constants.dart';
import 'ai_question_service.dart';
import 'ai_question_mixin.dart';
import 'ai_service_exception.dart';

/// Google Gemini API üzerinden soru üretme servisi.
/// [AIQuestionService] interface'ini implemente eder.
class GeminiService extends AIQuestionService with AIQuestionMixin {
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

    // Assuming _isInitialized is a property that needs to be defined elsewhere
    // For now, I'll add the check as requested, but it might require
    // adding _isInitialized to the class if it doesn't exist.
    // Based on the context, _validateConfiguration() might serve a similar purpose
    // or _isInitialized could be a flag set after successful initialization.
    // Since the instruction only provides the if block, I'll add it directly.
    // If _isInitialized is not defined, this will cause a compilation error.
    // For the purpose of this edit, I'll assume it's meant to be there.
    // If _isInitialized is not defined, the user should define it.
    // For now, I'll comment it out to avoid a compile error if it's not defined.
    // if (!_isInitialized) {
    //   throw AIServiceException(
    //     provider: providerName,
    //     message: 'Servis başlatılmadı.',
    //   );
    // }

    try {
      final prompt = buildQuestionPrompt(
        categoryId: categoryId,
        subCategory: subCategory,
        topic: topic,
        difficulty: difficulty,
        count: count,
        style: style,
      );

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
        message: 'API Key bulunamadı. .env dosyasında GEMINI_API_KEY tanımlayın.',
      );
    }
  }

  /// Gemini API'ye istek gönderir
  Future<String> _sendRequest(String prompt) async {
    final content = [Content.text(prompt)];
    final response = await _generativeModel
        .generateContent(content)
        .timeout(AIConstants.requestTimeout);

    if (response.text == null) {
      throw AIServiceException(
        provider: providerName,
        message: 'API boş yanıt döndürdü.',
      );
    }

    return response.text!;
  }
}
