import 'package:flutter/material.dart';

import '../enums/quiz_type.dart';
import '../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import '../games/quiz/models/quiz_config.dart';

class QuizCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final QuizType type;
  final String route;
  final bool isActive;
  final QuizConfig? config;

  const QuizCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.type,
    required this.route,
    this.isActive = true,
    this.config,
  });

  // Kullanılabilir quizlerin listesi
  static List<QuizCategory> get availableCategories => [
    QuizCategory(
      id: 'vocabulary_quiz',
      title: AppStrings.vocabQuizTitle,
      description: AppStrings.vocabQuizDesc,
      icon: Icons.translate,
      color: AppTheme.vocabPrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.vocabulary),
      type: QuizType.vocabulary,
      route: '/game/vocabulary_quiz',
      isActive: true,
      config: QuizConfig(
        categoryId: 'vocabulary_quiz',
        gameType: 'vocabulary_quiz',
        title: AppStrings.vocabQuizTitle,
        subtitle: AppStrings.vocabQuizDesc,
        emoji: '📚',
        gradientColors: AppTheme.getCategoryColors(QuizType.vocabulary),
      ),
    ),
    QuizCategory(
      id: 'general_culture',
      title: AppStrings.generalCultureQuizTitle,
      description: AppStrings.generalCultureQuizDesc,
      icon: Icons.public,
      color: AppTheme.generalCulturePrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.generalCulture),
      type: QuizType.generalCulture,
      route: '/game/general_culture',
      isActive: false, 
      config: QuizConfig(
        categoryId: 'general_culture',
        gameType: 'general_culture_quiz',
        title: AppStrings.generalCultureQuizTitle,
        subtitle: AppStrings.generalCultureQuizDesc,
        emoji: '🌍',
        gradientColors: AppTheme.getCategoryColors(QuizType.generalCulture),
      ),
    ),
    QuizCategory(
      id: 'ayt_yks',
      title: AppStrings.aytQuizTitle,
      description: AppStrings.aytQuizDesc,
      icon: Icons.school,
      color: AppTheme.aytPrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.ayt),
      type: QuizType.ayt,
      route: '/game/ayt_yks',
      isActive: false, 
      config: QuizConfig(
        categoryId: 'ayt_yks',
        gameType: 'ayt_yks_quiz',
        title: AppStrings.aytQuizTitle,
        subtitle: AppStrings.aytQuizDesc,
        emoji: '🎓',
        gradientColors: AppTheme.getCategoryColors(QuizType.ayt),
      ),
    ),
    QuizCategory(
      id: 'kpss',
      title: AppStrings.kpssQuizTitle,
      description: AppStrings.kpssQuizDesc,
      icon: Icons.school,
      color: AppTheme.kpssPrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.kpss),
      type: QuizType.kpss,
      route: '/game/kpss',
      isActive: false, 
      config: QuizConfig(
        categoryId: 'kpss',
        gameType: 'kpss_quiz',
        title: AppStrings.kpssQuizTitle,
        subtitle: AppStrings.kpssQuizDesc,
        emoji: '📖',
        gradientColors: AppTheme.getCategoryColors(QuizType.kpss),
      ),
    ),
    QuizCategory(
      id: 'TUS',
      title: AppStrings.tusQuizTitle,
      description: AppStrings.tusQuizDesc,
      icon: Icons.school,
      color: AppTheme.tusPrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.tus),
      type: QuizType.tus,
      route: '/game/tus',
      isActive: true,
      config: QuizConfig(
        categoryId: 'TUS',
        gameType: 'tus_quiz',
        title: AppStrings.tusQuizTitle,
        subtitle: AppStrings.tusQuizDesc,
        emoji: '🩺',
        gradientColors: AppTheme.getCategoryColors(QuizType.tus),
      ),
    ),
    QuizCategory(
      id: 'PDR',
      title: AppStrings.pdrQuizTitle,
      description: AppStrings.pdrQuizDesc,
      icon: Icons.psychology,
      color: AppTheme.pdrPrimary,
      gradientColors: AppTheme.getCategoryColors(QuizType.pdr),
      type: QuizType.pdr,
      route: '/game/pdr',
      isActive: true,
      config: QuizConfig(
        categoryId: 'PDR',
        gameType: 'pdr_quiz',
        title: AppStrings.pdrQuizTitle,
        subtitle: AppStrings.pdrQuizDesc,
        emoji: '🧠',
        gradientColors: AppTheme.getCategoryColors(QuizType.pdr),
        hasDifficultySelection: false,
      ),
    ),
  ];
}

/* 
  =============================================================================
  🚧 GELECEK GELİŞTİRİCİ İÇİN NOTLAR (FUTURE IMPROVEMENTS) 🚧
  =============================================================================
  
  Bu sınıf şu an uygulama içi statik (hardcoded) veri kaynağı olarak çalışıyor.
  Gelecekte daha dinamik ve ölçeklenebilir olması için şu adımlar atılmalı:

  1. 🔥 Remote Config / Firestore Entegrasyonu:
     - Şu an 'availableCategories' listesi kodun içinde gömülü. 
     - İleride bu liste Firebase Remote Config veya Firestore'dan çekilmeli.
     - Böylece market güncellemesi yapmadan yeni kategori ekleyip çıkarabiliriz.
     - Bu geçiş yapıldığında 'fromJson' ve 'toJson' metodları eklenmeli.

  2. 🎨 Görsel Zenginleştirme:
     - Şu an sadece 'IconData' ve 'emoji' kullanılıyor.
     - 'imageUrl' (URL) veya 'assetPath' (Local) alanları eklenerek, 
       her kategoriye özel detaylı arka plan görselleri veya Lottie animasyonları eklenebilir.

  3. 🔢 Dinamik Sıralama:
     - 'sortOrder' (int) alanı eklenerek kategorilerin ekrandaki sırası 
       sunucu tarafından dinamik olarak yönetilmeli.

  4. 🔒 Erişim Kontrolü:
     - 'isPremium', 'minLevel' veya 'requiredPoints' gibi alanlar eklenerek,
       bazı kategorilerin sadece belirli seviyedeki kullanıcılara açılması sağlanabilir.

  5. 🧪 Test & Type Safety:
     - ID'lerin string olması hata riskini artırıyor. 
     - 'QuizCategoryID' gibi bir enum veya 'inline class' (extension type) 
       kullanılarak tip güvenliği artırılabilir.
       
  Unutma: Yeni bir alan eklerken Localization (AppStrings) ve Theme (AppTheme) 
  yapılarını kullanmaya özen göster. Hardcoded string ve renk kullanmaktan kaçın!
  =============================================================================
*/
