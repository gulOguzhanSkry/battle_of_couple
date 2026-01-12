import 'package:flutter/material.dart';

/// Oyun sabitleri ve konfigürasyonu
class GameConstants {
  // Oyun Süresi
  static const int gameDurationSeconds = 60;
  
  // Kalp Ayarları
  static const double heartMinSize = 40.0;
  static const double heartMaxSize = 70.0;
  static const double heartMinSpeed = 80.0;
  static const double heartMaxSpeed = 180.0;
  static const double heartSpawnIntervalMs = 800.0;
  static const int maxHeartsOnScreen = 12;
  
  // Altın Kalp Spawn Olasılığı (0-1 arası)
  static const double goldenHeartChance = 0.15;
  static const double bonusHeartChance = 0.10;
  
  // Ok Ayarları
  static const double arrowLength = 60.0;
  static const double arrowWidth = 12.0;
  static const double arrowMinPower = 0.3;
  static const double arrowMaxPower = 1.0;
  static const double arrowSpeed = 800.0;
  static const double arrowRotationSpeed = 2.0; // radyan/saniye
  
  // Puan Ayarları
  static const int normalHeartPoints = 10;
  static const int goldenHeartPoints = 50;
  static const int bonusHeartPoints = 25;
  static const int comboMultiplierThreshold = 3;
  static const double comboMultiplier = 1.5;
  
  // Efekt Süreleri (milisaniye)
  static const int explosionDurationMs = 500;
  static const int scorePopupDurationMs = 800;
  static const int comboDurationMs = 1000;
  static const int screenShakeDurationMs = 150;
  
  // Renkler
  static const Color normalHeartColor = Color(0xFFE91E63);
  static const Color goldenHeartColor = Color(0xFFFFD700);
  static const Color bonusHeartColor = Color(0xFF9C27B0);
  static const Color arrowColor = Color(0xFF4CAF50);
  static const Color player1Color = Color(0xFF2196F3);
  static const Color player2Color = Color(0xFFFF5722);
  
  // Gradyanlar
  static const List<Color> backgroundGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
  ];
  
  static const List<Color> heartGlowGradient = [
    Color(0xFFFF6B9D),
    Color(0xFFE91E63),
    Color(0xFFC2185B),
  ];
  
  // Parçacık Efekt Ayarları
  static const int particleCount = 12;
  static const double particleMinSpeed = 100.0;
  static const double particleMaxSpeed = 300.0;
  static const double particleMinSize = 4.0;
  static const double particleMaxSize = 10.0;
  
  // Ses Dosyaları (assets klasörü altında)
  static const String soundShoot = 'assets/sounds/hit_normal.wav';
  static const String soundHitNormal = 'assets/sounds/hit_normal.wav';
  static const String soundHitGold = 'assets/sounds/hit_gold.wav';
  static const String soundCombo = 'assets/sounds/combo.wav';
  static const String soundGameOver = 'assets/sounds/game_over.wav';
  static const String soundCountdown = 'assets/sounds/countdown.wav';
  static const String soundWin = 'assets/sounds/win.wav';
}

/// Kalp türleri
enum HeartType {
  normal,
  golden,
  bonus,
}

/// Oyuncu pozisyonu
enum PlayerPosition {
  top,
  bottom,
}

/// Oyun modu
enum GameMode {
  solo,       // Tek oyuncu
  couplesVs,  // Çiftler karşılıklı
  partners,   // Partnerler birlikte
}

/// Oyun durumu
enum GameStatus {
  waiting,    // Başlamayı bekliyor
  countdown,  // Geri sayım
  playing,    // Oyun devam ediyor
  paused,     // Duraklatıldı
  finished,   // Bitti
}

extension HeartTypeExtension on HeartType {
  Color get color {
    switch (this) {
      case HeartType.normal:
        return GameConstants.normalHeartColor;
      case HeartType.golden:
        return GameConstants.goldenHeartColor;
      case HeartType.bonus:
        return GameConstants.bonusHeartColor;
    }
  }
  
  int get points {
    switch (this) {
      case HeartType.normal:
        return GameConstants.normalHeartPoints;
      case HeartType.golden:
        return GameConstants.goldenHeartPoints;
      case HeartType.bonus:
        return GameConstants.bonusHeartPoints;
    }
  }
}

extension PlayerPositionExtension on PlayerPosition {
  Color get color {
    switch (this) {
      case PlayerPosition.top:
        return GameConstants.player1Color;
      case PlayerPosition.bottom:
        return GameConstants.player2Color;
    }
  }
}
