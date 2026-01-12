import 'package:flutter/material.dart';

/// Her quiz kategorisi için config
/// Bu config ile aynı ekran yapısı farklı kategoriler için kullanılabilir
class QuizConfig {
  /// Firestore'daki kategori ID'si (TUS, kpss, vocabulary_quiz, general_culture, ayt_yks)
  final String categoryId;
  
  /// Matchmaking için game type (tus_quiz, kpss_quiz, vocabulary_quiz, etc.)
  final String gameType;
  
  /// Ekranda gösterilecek başlık
  final String title;
  
  /// Alt başlık / açıklama
  final String subtitle;
  
  /// Emoji ikonu
  final String emoji;
  
  /// Gradient renkleri
  final List<Color> gradientColors;
  
  /// Her seviye için varsayılan soru sayısı
  final int defaultQuestionCount;
  
  /// Solo modda zorluk seçimi olsun mu?
  final bool hasDifficultySelection;

  const QuizConfig({
    required this.categoryId,
    required this.gameType,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientColors,
    this.defaultQuestionCount = 10,
    this.hasDifficultySelection = true,
  });
}
