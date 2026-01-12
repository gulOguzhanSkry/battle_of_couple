import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/question_model.dart';
import '../../core/constants/ai_prompt_templates.dart';
import 'ai_question_service.dart';

/// AI servisler için ortak işlevsellik sağlayan mixin.
/// Prompt oluşturma ve JSON parsing mantığını merkezileştirir.
mixin AIQuestionMixin on AIQuestionService {
  
  /// Kategori bazlı soru üretme promptunu oluşturur.
  /// PromptBuilderFactory kullanarak ilgili kategorinin builder'ını seçer.
  String buildQuestionPrompt({
    required String categoryId,
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    // Factory pattern ile kategori bazlı builder al
    final promptBuilder = PromptBuilderFactory.getBuilder(categoryId);
    
    debugPrint('[AIQuestionMixin] Using ${promptBuilder.categoryDescription} prompt for category: $categoryId');
    
    return promptBuilder.buildPrompt(
      subCategory: subCategory,
      topic: topic,
      difficulty: difficulty,
      count: count,
      style: style,
    );
  }

  /// AI yanıtından JSON'ı temizler ve parse eder
  String cleanJsonResponse(String response) {
    return response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  /// JSON listesini QuestionModel listesine dönüştürür
  List<QuestionModel> parseQuestionsFromJson(
    String jsonString, {
    required String categoryId,
    String? subCategory,
    required String difficulty,
    required String userId,
  }) {
    final cleanJson = cleanJsonResponse(jsonString);
    final decoded = json.decode(cleanJson);
    
    // AI bazen object içinde array döndürebilir: {"questions": [...]}
    List<dynamic> jsonList;
    if (decoded is List) {
      jsonList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Map içindeki ilk List'i bul
      final listValue = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => <dynamic>[],
      );
      jsonList = listValue as List<dynamic>;
      debugPrint('[AIQuestionMixin] Extracted list from object wrapper, found ${jsonList.length} questions');
    } else {
      throw FormatException('Unexpected JSON format: expected List or Map, got ${decoded.runtimeType}');
    }

    return jsonList.map((data) {
      return QuestionModel(
        id: '', // ID oluşturma esnasında atanacak
        questionText: data['questionText'] as String,
        options: List<String>.from(data['options']),
        correctOptionIndex: data['correctOptionIndex'] as int,
        categoryId: categoryId,
        subCategory: subCategory, // Alt kategori parametreden al
        difficulty: difficulty,
        createdAt: DateTime.now(),
        createdBy: userId,
        // Opsiyonel alanlar - AI doldurmayabilir
        topic: data['topic'] as String?,
        explanation: data['explanation'] as String?,
        // imageUrl ve audioUrl AI tarafından üretilemez,
        // manuel olarak veya ayrı bir servis ile eklenebilir
        imageUrl: data['imageUrl'] as String?,
        audioUrl: data['audioUrl'] as String?,
      );
    }).toList();
  }

  /// Hata loglama
  void logError(String message, dynamic error) {
    debugPrint('[$providerName] $message: $error');
  }
}
