import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern romantic color palette
  static const Color primaryColor = Color(0xFFE91E63); // Pink
  static const Color secondaryColor = Color(0xFF9C27B0); // Purple
  static const Color accentColor = Color(0xFFFF4081); // Light Pink
  static const Color backgroundColor = Color(0xFFFAF8FC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF2D2D2D);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // Priority colors
  static const Color highPriorityColor = Color(0xFFE53935);
  static const Color mediumPriorityColor = Color(0xFFFFA726);
  static const Color lowPriorityColor = Color(0xFF66BB6A);

  // Soft pink button colors (açık pembe arka plan, koyu pembe yazı)
  static const Color softPinkBg = Color(0xFFFCE4EC); // Çok açık pembe
  static const Color softPinkText = Color(0xFFC2185B); // Koyu pembe
  
  // Action button colors (kontrast için)
  static const Color dangerBg = Color(0xFFFFEBEE); // Açık kırmızı
  static const Color dangerText = Color(0xFFB71C1C); // Koyu kırmızı
  static const Color confirmBg = Color(0xFFE8F5E9); // Açık yeşil
  static const Color confirmText = Color(0xFF2E7D32); // Koyu yeşil
  static const Color warningBg = Color(0xFFFFF3E0); // Açık turuncu
  static const Color warningText = Color(0xFFE65100); // Koyu turuncu

  // Game card colors
  static const Color heartShooterPrimary = Color(0xFFE91E63);
  static const Color heartShooterSecondary = Color(0xFFC2185B);
  static const Color quizHubPrimary = Color(0xFF673AB7);
  static const Color quizHubSecondary = Color(0xFF512DA8);
  static const Color marimoPrimary = Color(0xFF009688);
  static const Color marimoSecondary = Color(0xFF00796B);
  static const Color coupleVsColor = Color(0xFF2196F3);
  static const Color rafflesColor = Color(0xFF9C27B0);
  static const Color eventsColor = Color(0xFF673AB7);

  // Login screen colors
  static const Color loginGradientStart = Color(0xFFFF6B9D);
  static const Color loginGradientMiddle = Color(0xFFFF8E8E);
  static const Color loginGradientEnd = Color(0xFFFFB3BA);

  // Leaderboard screen colors
  static const Color leaderboardBgStart = Color(0xFF0F0C29);
  static const Color leaderboardBgMiddle = Color(0xFF302B63);
  static const Color leaderboardBgEnd = Color(0xFF24243E);
  static const Color goldRank = Color(0xFFFFD700);
  static const Color silverRank = Color(0xFFC0C0C0);
  static const Color bronzeRank = Color(0xFFCD7F32);

  // QuizHub screen colors
  static const Color quizHubBgStart = Color(0xFFFFF0F5);  // Lavender blush
  static const Color quizHubBgMiddle = Color(0xFFF3E5F5); // Light purple
  static const Color quizHubBgEnd = Color(0xFFFCE4EC);    // Light pink

  // Quiz Category Colors
  static const Color vocabPrimary = Color(0xFFFFD700);
  static const Color vocabSecondary = Color(0xFFFFA500);
  static const Color generalCulturePrimary = Color(0xFF00BFA5);
  static const Color generalCultureSecondary = Color(0xFF009688);
  static const Color aytPrimary = Color(0xFF6200EA);
  static const Color aytSecondary = Color(0xFF7C4DFF);
  static const Color kpssPrimary = Color(0xFF10B981); // Green
  static const Color kpssSecondary = Color(0xFF34D399);
  static const Color tusPrimary = Color(0xFF6366F1); // Indigo
  static const Color tusSecondary = Color(0xFF8B5CF6);
  static const Color pdrPrimary = Color(0xFF00ACC1); // Cyan
  static const Color pdrSecondary = Color(0xFF26C6DA);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFF0F5), Color(0xFFF3E5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Get the main theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // Text theme
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimaryColor,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceColor,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textLightColor,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
    );
  }

  // Helper method to get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
      case 'high':
        return highPriorityColor;
      case 'orta':
      case 'medium':
        return mediumPriorityColor;
      case 'düşük':
      case 'low':
        return lowPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }

  // Helper method to create gradient container
  static BoxDecoration gradientDecoration({
    Gradient? gradient,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Helper method to create card decoration
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Helper method to get gradient colors by QuizType
  static List<Color> getCategoryColors(dynamic type) {
    // Note: Parameter is dynamic to avoid cyclic dependency if we import QuizType here.
    // Ideally should be QuizType, but AppTheme is low level.
    // Assuming type.toString() contains the enum name.
    
    final typeStr = type.toString().split('.').last;
    
    switch (typeStr) {
      case 'vocabulary':
        return [vocabPrimary, vocabSecondary];
      case 'generalCulture':
        return [generalCulturePrimary, generalCultureSecondary];
      case 'ayt':
        return [aytPrimary, aytSecondary];
      case 'kpss':
        return [kpssPrimary, kpssSecondary];
      case 'tus':
        return [tusPrimary, tusSecondary];
      case 'pdr':
        return [pdrPrimary, pdrSecondary];
      default:
        return [primaryColor, secondaryColor];
    }
  }
}
