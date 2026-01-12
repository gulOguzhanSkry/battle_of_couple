import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'game_constants.dart';
import 'game_state.dart';

/// Oyun motoru - ana oyun döngüsünü yönetir
class GameEngine {
  /// Oyun durumu
  final GameState gameState;
  
  /// Ticker provider (genellikle bir StatefulWidget)
  final TickerProvider vsync;
  
  /// Ana oyun döngüsü ticker'ı
  Ticker? _ticker;
  
  /// Son frame zamanı
  Duration _lastFrameTime = Duration.zero;
  
  /// Geri sayım timer'ı
  Timer? _countdownTimer;
  
  /// Oyun süresi timer'ı
  Timer? _gameTimer;
  
  /// Geri sayım değeri
  int _countdownValue = 3;
  int get countdownValue => _countdownValue;
  
  /// Geri sayım callback'i
  Function(int)? onCountdownTick;
  
  /// Oyun başladı callback'i
  Function()? onGameStart;
  
  /// Oyun bitti callback'i
  Function()? onGameEnd;

  GameEngine({
    required this.gameState,
    required this.vsync,
  });

  /// Motoru başlat
  void start() {
    gameState.startGame();
    _startCountdown();
  }
  
  /// Geri sayımı başlat
  void _startCountdown() {
    _countdownValue = 3;
    onCountdownTick?.call(_countdownValue);
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      
      if (_countdownValue > 0) {
        onCountdownTick?.call(_countdownValue);
      } else {
        timer.cancel();
        _startGameLoop();
      }
    });
  }
  
  /// Oyun döngüsünü başlat
  void _startGameLoop() {
    gameState.onCountdownComplete();
    onGameStart?.call();
    
    // Ana oyun döngüsü (60 FPS)
    _ticker = vsync.createTicker(_onTick);
    _ticker!.start();
    _lastFrameTime = Duration.zero;
    
    // Süre sayacı
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.status == GameStatus.playing) {
        gameState.decrementTime();
        
        if (gameState.remainingTime <= 0) {
          timer.cancel();
          _onGameEnd();
        }
      }
    });
  }
  
  /// Her frame'de çağrılır
  void _onTick(Duration elapsed) {
    if (gameState.status != GameStatus.playing) return;
    
    // Delta time hesapla (saniye cinsinden)
    final dt = _lastFrameTime == Duration.zero
        ? 0.016 // İlk frame için ~60 FPS
        : (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    
    _lastFrameTime = elapsed;
    
    // Oyun durumunu güncelle
    gameState.update(dt.clamp(0.0, 0.1).toDouble()); // Max 100ms delta
  }
  
  /// Oyun bitti
  void _onGameEnd() {
    gameState.endGame();
    _ticker?.stop();
    onGameEnd?.call();
  }
  
  /// Oyunu duraklat
  void pause() {
    gameState.pauseGame();
    _ticker?.stop();
  }
  
  /// Oyuna devam et
  void resume() {
    gameState.resumeGame();
    _ticker?.start();
    _lastFrameTime = Duration.zero; // Reset frame time
  }
  
  /// Motoru temizle
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
  }
  
  /// Oyunu yeniden başlat
  void restart() {
    dispose();
    gameState.reset();
    start();
  }
  
  // ============ Ok Kontrol Metodları ============
  
  /// Alt ok açısını döndür (delta ile)
  void rotateBottomArrow(double deltaAngle) {
    gameState.rotateArrow(PlayerPosition.bottom, deltaAngle);
  }
  
  /// Üst ok açısını döndür (delta ile)
  void rotateTopArrow(double deltaAngle) {
    gameState.rotateArrow(PlayerPosition.top, deltaAngle);
  }
  
  /// Alt ok açısını direkt ayarla
  void setBottomArrowAngle(double angle) {
    gameState.setArrowAngle(PlayerPosition.bottom, angle);
  }
  
  /// Üst ok açısını direkt ayarla
  void setTopArrowAngle(double angle) {
    gameState.setArrowAngle(PlayerPosition.top, angle);
  }
  
  /// Alt ok gücünü ayarla
  void setBottomArrowPower(double power) {
    gameState.setArrowPower(PlayerPosition.bottom, power);
  }
  
  /// Üst ok gücünü ayarla
  void setTopArrowPower(double power) {
    gameState.setArrowPower(PlayerPosition.top, power);
  }
  
  /// Alt oku fırlat
  void fireBottomArrow() {
    gameState.fireArrow(PlayerPosition.bottom);
  }
  
  /// Üst oku fırlat
  void fireTopArrow() {
    gameState.fireArrow(PlayerPosition.top);
  }
}
