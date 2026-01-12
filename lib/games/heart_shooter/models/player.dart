import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Oyuncu modeli
class Player {
  /// Oyuncu kimliği
  final String id;
  
  /// Oyuncu adı
  final String name;
  
  /// Oyuncu pozisyonu (üst/alt)
  final PlayerPosition position;
  
  /// Toplam puan
  int score;
  
  /// Mevcut combo sayısı
  int combo;
  
  /// En yüksek combo
  int maxCombo;
  
  /// Vurulan kalp sayısı
  int heartsHit;
  
  /// Altın kalp sayısı
  int goldenHeartsHit;
  
  /// Atılan ok sayısı
  int arrowsFired;
  
  /// Son vuruş zamanı (combo için)
  DateTime? lastHitTime;

  Player({
    required this.id,
    required this.name,
    required this.position,
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.heartsHit = 0,
    this.goldenHeartsHit = 0,
    this.arrowsFired = 0,
    this.lastHitTime,
  });

  /// Oyuncu rengi
  Color get color => position.color;
  
  /// İsabet oranı (%)
  double get accuracy {
    if (arrowsFired == 0) return 0;
    return (heartsHit / arrowsFired * 100);
  }
  
  /// Combo çarpanı
  double get comboMultiplier {
    if (combo >= GameConstants.comboMultiplierThreshold) {
      return GameConstants.comboMultiplier;
    }
    return 1.0;
  }
  
  /// Kalp vurulduğunda çağır
  void onHeartHit(HeartType heartType, int basePoints) {
    final now = DateTime.now();
    
    // Combo kontrolü (son vuruştan 2 saniye içinde yeni vuruş)
    if (lastHitTime != null && 
        now.difference(lastHitTime!).inMilliseconds < 2000) {
      combo++;
    } else {
      combo = 1;
    }
    
    // En yüksek combo güncelle
    if (combo > maxCombo) {
      maxCombo = combo;
    }
    
    // Puanı hesapla (combo çarpanı ile)
    final points = (basePoints * comboMultiplier).round();
    score += points;
    
    // İstatistikleri güncelle
    heartsHit++;
    if (heartType == HeartType.golden) {
      goldenHeartsHit++;
    }
    
    lastHitTime = now;
  }
  
  /// Ok atıldığında çağır
  void onArrowFired() {
    arrowsFired++;
  }
  
  /// Combo'yu sıfırla (ıskalama durumunda)
  void resetCombo() {
    combo = 0;
  }
  
  /// Oyuncuyu sıfırla
  void reset() {
    score = 0;
    combo = 0;
    maxCombo = 0;
    heartsHit = 0;
    goldenHeartsHit = 0;
    arrowsFired = 0;
    lastHitTime = null;
  }
  
  /// Kopyasını oluştur
  Player copyWith({
    int? score,
    int? combo,
    int? maxCombo,
    int? heartsHit,
    int? goldenHeartsHit,
    int? arrowsFired,
    DateTime? lastHitTime,
  }) {
    return Player(
      id: id,
      name: name,
      position: position,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      heartsHit: heartsHit ?? this.heartsHit,
      goldenHeartsHit: goldenHeartsHit ?? this.goldenHeartsHit,
      arrowsFired: arrowsFired ?? this.arrowsFired,
      lastHitTime: lastHitTime ?? this.lastHitTime,
    );
  }
  
  /// JSON'a dönüştür (Firebase için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position.name,
      'score': score,
      'combo': combo,
      'maxCombo': maxCombo,
      'heartsHit': heartsHit,
      'goldenHeartsHit': goldenHeartsHit,
      'arrowsFired': arrowsFired,
      'accuracy': accuracy,
    };
  }
  
  /// JSON'dan oluştur
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      position: PlayerPosition.values.firstWhere(
        (p) => p.name == json['position'],
        orElse: () => PlayerPosition.bottom,
      ),
      score: json['score'] as int? ?? 0,
      combo: json['combo'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      heartsHit: json['heartsHit'] as int? ?? 0,
      goldenHeartsHit: json['goldenHeartsHit'] as int? ?? 0,
      arrowsFired: json['arrowsFired'] as int? ?? 0,
    );
  }
}
