import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Oyundaki kalp nesnesi
class Heart {
  /// Benzersiz kimlik
  final String id;
  
  /// Ekrandaki pozisyon
  Offset position;
  
  /// Hareket yönü (normalize edilmiş)
  Offset velocity;
  
  /// Hareket hızı (piksel/saniye)
  final double speed;
  
  /// Kalp boyutu
  final double size;
  
  /// Kalp türü
  final HeartType type;
  
  /// Aktif mi (vurulmamış)
  bool isActive;
  
  /// Animasyon fazı (0-1 arası, pulse için)
  double animationPhase;
  
  /// Oluşturulma zamanı
  final DateTime createdAt;

  Heart({
    required this.id,
    required this.position,
    required this.velocity,
    required this.speed,
    required this.size,
    required this.type,
    this.isActive = true,
    this.animationPhase = 0.0,
  }) : createdAt = DateTime.now();

  /// Bu kalbin kazandırdığı puan
  int get points => type.points;
  
  /// Kalp rengi
  Color get color => type.color;
  
  /// Çarpışma yarıçapı
  double get hitRadius => size / 2;
  
  /// Belirtilen pozisyonla çarpışma kontrolü
  bool checkCollision(Offset point, double pointRadius) {
    final distance = (position - point).distance;
    return distance <= (hitRadius + pointRadius);
  }
  
  /// Kalbi güncelle (dt: delta time saniye cinsinden)
  void update(double dt, Size screenSize) {
    if (!isActive) return;
    
    // Pozisyonu güncelle
    position = Offset(
      position.dx + velocity.dx * speed * dt,
      position.dy + velocity.dy * speed * dt,
    );
    
    // Ekran sınırlarından sekme
    if (position.dx - size / 2 <= 0 || position.dx + size / 2 >= screenSize.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
      position = Offset(
        position.dx.clamp(size / 2, screenSize.width - size / 2),
        position.dy,
      );
    }
    
    // Animasyon fazını güncelle (pulse efekti için)
    animationPhase = (animationPhase + dt * 3) % (2 * pi);
  }
  
  /// Pulse animasyon skalası (0.9 - 1.1 arası)
  double get pulseScale => 1.0 + sin(animationPhase) * 0.1;
  
  /// Rastgele kalp oluştur
  static Heart spawn({
    required Size screenSize,
    required Random random,
  }) {
    // Kalp türünü belirle
    HeartType type;
    final chance = random.nextDouble();
    if (chance < GameConstants.goldenHeartChance) {
      type = HeartType.golden;
    } else if (chance < GameConstants.goldenHeartChance + GameConstants.bonusHeartChance) {
      type = HeartType.bonus;
    } else {
      type = HeartType.normal;
    }
    
    // Rastgele boyut
    final size = GameConstants.heartMinSize +
        random.nextDouble() * (GameConstants.heartMaxSize - GameConstants.heartMinSize);
    
    // Rastgele hız
    final speed = GameConstants.heartMinSpeed +
        random.nextDouble() * (GameConstants.heartMaxSpeed - GameConstants.heartMinSpeed);
    
    // Ekranın ortasında rastgele spawn (üst ve alt okların erişebileceği yerde)
    final centerY = screenSize.height / 2;
    final spawnZoneHeight = screenSize.height * 0.4; // Ortadaki %40'lık alan
    
    final position = Offset(
      size / 2 + random.nextDouble() * (screenSize.width - size),
      centerY - spawnZoneHeight / 2 + random.nextDouble() * spawnZoneHeight,
    );
    
    // Rastgele hareket yönü
    final angle = random.nextDouble() * 2 * pi;
    final velocity = Offset(cos(angle), sin(angle));
    
    // Statik sayaç ile benzersiz ID üret
    _heartIdCounter++;
    
    return Heart(
      id: 'heart_${_heartIdCounter}_${random.nextInt(1000)}',
      position: position,
      velocity: velocity,
      speed: speed,
      size: size,
      type: type,
    );
  }
  
  /// Benzersiz ID için statik sayaç
  static int _heartIdCounter = 0;
  
  /// Kopyasını oluştur
  Heart copyWith({
    Offset? position,
    Offset? velocity,
    bool? isActive,
    double? animationPhase,
  }) {
    return Heart(
      id: id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      speed: speed,
      size: size,
      type: type,
      isActive: isActive ?? this.isActive,
      animationPhase: animationPhase ?? this.animationPhase,
    );
  }
}
