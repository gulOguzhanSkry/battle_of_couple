import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/question_model.dart';
import '../../../enums/quiz_difficulty.dart';

/// Tüm quiz kategorileri için ortak soru servisi
/// Firestore'daki 'questions' koleksiyonundan soru çeker
class QuizQuestionService {
  static final QuizQuestionService _instance = QuizQuestionService._internal();
  factory QuizQuestionService() => _instance;
  QuizQuestionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Belirli kategoriden sorular getir
  /// 
  /// [categoryId] - Firestore'daki kategori ID'si (TUS, kpss, vocabulary_quiz, etc.)
  /// [difficulty] - Zorluk seviyesi (null = karışık zorluk)
  /// [count] - Kaç soru getirilecek
  /// [seed] - Multiplayer senkronizasyonu için seed (aynı seed = aynı sorular)
  Future<List<QuestionModel>> getQuestions({
    required String categoryId,
    String? difficulty,
    int count = 10,
    String? seed,
  }) async {
    try {
      Query query = _firestore.collection('questions')
          .where('categoryId', isEqualTo: categoryId);
      
      // Zorluk filtresi varsa ekle
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('[QuizQuestionService] No questions found for category: $categoryId');
        return [];
      }
      
      final questions = snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList();
      
      // Seed varsa deterministic random (multiplayer için aynı sıra)
      final random = seed != null ? Random(seed.hashCode) : _random;
      questions.shuffle(random);
      
      debugPrint('[QuizQuestionService] Loaded ${questions.length} questions for $categoryId');
      return questions.take(count).toList();
    } catch (e) {
      debugPrint('[QuizQuestionService] Error loading questions: $e');
      return [];
    }
  }

  /// Solo mod için zorluk seviyesine göre sorular
  Future<List<QuestionModel>> getQuestionsForSolo({
    required String categoryId,
    required QuizDifficulty difficulty,
    int? count,
  }) async {
    return getQuestions(
      categoryId: categoryId,
      difficulty: _difficultyToString(difficulty),
      count: count ?? difficulty.questionCount,
      seed: null,
    );
  }

  /// Multiplayer mod için karışık zorlukta sorular
  Future<List<QuestionModel>> getQuestionsForMultiplayer({
    required String categoryId,
    required String roomCode,
    int count = 10,
  }) async {
    return getQuestions(
      categoryId: categoryId,
      difficulty: null, // Karışık zorluk
      count: count,
      seed: roomCode, // Aynı oda = aynı sorular
    );
  }

  /// Solo karışık zorluk modu için sorular
  /// Tüm zorluk seviyelerinden rastgele sorular getirir
  Future<List<QuestionModel>> getQuestionsForMixedDifficulty({
    required String categoryId,
    int count = 10,
  }) async {
    return getQuestions(
      categoryId: categoryId,
      difficulty: null, // Zorluk filtresi yok - karışık mod
      count: count,
      seed: null, // Her seferinde farklı sorular
    );
  }

  String _difficultyToString(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'easy';
      case QuizDifficulty.medium:
        return 'medium';
      case QuizDifficulty.hard:
        return 'hard';
    }
  }
}
