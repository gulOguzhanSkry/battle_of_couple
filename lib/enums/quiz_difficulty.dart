import '../core/constants/app_strings.dart';

enum QuizDifficulty {
  easy,   // 30 sn/soru, 10 soru = 300 sn toplam
  medium, // 25 sn/soru, 10 soru = 250 sn toplam
  hard,   // 20 sn/soru, 10 soru = 200 sn toplam
}

extension QuizDifficultyExtension on QuizDifficulty {
  String get displayName {
    switch (this) {
      case QuizDifficulty.easy:
        return AppStrings.diffEasy;
      case QuizDifficulty.medium:
        return AppStrings.diffMedium;
      case QuizDifficulty.hard:
        return AppStrings.diffHard;
    }
  }

  String get description {
    return '$timePerQuestion ${AppStrings.diffDescriptionSeconds}, $questionCount ${AppStrings.diffDescriptionQuestions}';
  }

  int get questionCount => 10;

  int get timePerQuestion {
    switch (this) {
      case QuizDifficulty.easy:
        return 30;
      case QuizDifficulty.medium:
        return 25;
      case QuizDifficulty.hard:
        return 20;
    }
  }
}
