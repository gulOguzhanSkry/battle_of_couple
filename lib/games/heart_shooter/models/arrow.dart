import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Ok nesnesi - hem atış kontrolü hem de uçan ok için
class Arrow {
  /// Benzersiz kimlik
  final String id;
  
  /// Ok açısı (radyan cinsinden, 0 = sağa, PI = sola)
  double angle;
  
  /// Başlangıç pozisyonu (ok tabanı)
  final Offset startPosition;
  
  /// Mevcut pozisyon (uçan ok için)
  Offset currentPosition;
  
  /// Germe gücü (0-1 arası)
  double power;
  
  /// Uçuyor mu?
  bool isFlying;
  
  /// Hangi oyuncuya ait
  final PlayerPosition owner;
  
  /// Oluşturulma zamanı
  final DateTime createdAt;

  Arrow({
    required this.id,
    required this.angle,
    required this.startPosition,
    Offset? currentPosition,
    this.power = 0.0,
    this.isFlying = false,
    required this.owner,
  })  : currentPosition = currentPosition ?? startPosition,
        createdAt = DateTime.now();

  /// Ok ucu pozisyonu (atış kontrolündeyken)
  Offset get tipPosition {
    final length = GameConstants.arrowLength * (1 + power * 0.5);
    final direction = owner == PlayerPosition.bottom ? -1.0 : 1.0;
    return Offset(
      startPosition.dx + cos(angle) * length,
      startPosition.dy + sin(angle) * length * direction,
    );
  }
  
  /// Ok yönü (normalize edilmiş vektör)
  Offset get direction {
    final dir = owner == PlayerPosition.bottom ? -1.0 : 1.0;
    return Offset(cos(angle), sin(angle) * dir);
  }
  
  /// Ok hızı (piksel/saniye)
  double get speed => GameConstants.arrowSpeed * (GameConstants.arrowMinPower + power * (1 - GameConstants.arrowMinPower));
  
  /// Çarpışma yarıçapı
  double get hitRadius => GameConstants.arrowWidth / 2;
  
  /// Oku güncelle (dt: delta time saniye cinsinden)
  void update(double dt) {
    if (!isFlying) return;
    
    currentPosition = Offset(
      currentPosition.dx + direction.dx * speed * dt,
      currentPosition.dy + direction.dy * speed * dt,
    );
  }
  
  /// Ekran dışına çıktı mı?
  bool isOutOfBounds(Size screenSize) {
    return currentPosition.dx < -50 ||
           currentPosition.dx > screenSize.width + 50 ||
           currentPosition.dy < -50 ||
           currentPosition.dy > screenSize.height + 50;
  }
  
  /// Oku fırlat
  Arrow launch() {
    return Arrow(
      id: id,
      angle: angle,
      startPosition: startPosition,
      currentPosition: tipPosition,
      power: power,
      isFlying: true,
      owner: owner,
    );
  }
  
  /// Açıyı döndür (delta radyan cinsinden)
  void rotate(double deltaAngle) {
    if (isFlying) return;
    
    // 0 ile PI arası sınırla (180 derece)
    angle = (angle + deltaAngle).clamp(0.0, pi);
  }
  
  /// Açıyı direkt ayarla (radyan cinsinden)
  void setAngle(double newAngle) {
    if (isFlying) return;
    
    // 0 ile PI arası sınırla (180 derece)
    angle = newAngle.clamp(0.1, pi - 0.1);
  }
  
  /// Germe gücünü ayarla
  void setPower(double newPower) {
    if (isFlying) return;
    power = newPower.clamp(0.0, 1.0);
  }
  
  /// Kopyasını oluştur
  Arrow copyWith({
    double? angle,
    Offset? currentPosition,
    double? power,
    bool? isFlying,
  }) {
    return Arrow(
      id: id,
      angle: angle ?? this.angle,
      startPosition: startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      power: power ?? this.power,
      isFlying: isFlying ?? this.isFlying,
      owner: owner,
    );
  }
  
  /// Yeni ok oluştur
  static Arrow create({
    required PlayerPosition owner,
    required Size screenSize,
  }) {
    final startY = (owner == PlayerPosition.bottom
        ? screenSize.height - 80
        : 80).toDouble();
    
    return Arrow(
      id: '${owner.name}_${DateTime.now().millisecondsSinceEpoch}',
      angle: pi / 2, // Başlangıçta yukarı/aşağı bakıyor
      startPosition: Offset(screenSize.width / 2, startY),
      owner: owner,
    );
  }
}
