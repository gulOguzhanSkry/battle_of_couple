import 'dart:math';
import 'package:flutter/material.dart';
import 'game_constants.dart';
import 'models/heart.dart';
import 'models/arrow.dart';
import 'models/player.dart';

/// Oyunun tüm durumunu tutan sınıf
class GameState extends ChangeNotifier {
  /// Oyun modu
  final GameMode gameMode;
  
  /// Oyun durumu
  GameStatus _status = GameStatus.waiting;
  GameStatus get status => _status;
  
  /// Kalan süre (saniye)
  int _remainingTime = GameConstants.gameDurationSeconds;
  int get remainingTime => _remainingTime;
  
  /// Oyuncular
  late Player _player1;
  late Player _player2;
  Player get player1 => _player1;
  Player get player2 => _player2;
  
  /// Ekrandaki kalpler
  final List<Heart> _hearts = [];
  List<Heart> get hearts => List.unmodifiable(_hearts);
  
  /// Uçan oklar
  final List<Arrow> _flyingArrows = [];
  List<Arrow> get flyingArrows => List.unmodifiable(_flyingArrows);
  
  /// Atış kontrol okları
  Arrow? _bottomArrow;
  Arrow? _topArrow;
  Arrow? get bottomArrow => _bottomArrow;
  Arrow? get topArrow => _topArrow;
  
  /// Ok fırlatabilir mi kontrolü (ekranda uçan ok yoksa fırlatabilir)
  bool get canFireBottom => !_flyingArrows.any((a) => a.owner == PlayerPosition.bottom);
  bool get canFireTop => !_flyingArrows.any((a) => a.owner == PlayerPosition.top);

  
  /// Efektler için callback'ler
  Function(Offset position, Color color)? onHeartHit;
  Function(int points, Offset position)? onScorePopup;
  Function(int combo, PlayerPosition player)? onCombo;
  Function()? onScreenShake;
  
  /// Ekran boyutu
  Size _screenSize = Size.zero;
  Size get screenSize => _screenSize;
  
  /// Rastgele sayı üreteci
  final Random _random = Random();
  
  /// Son kalp spawn zamanı
  DateTime _lastHeartSpawn = DateTime.now();

  GameState({required this.gameMode}) {
    _initializePlayers();
  }

  /// Oyuncuları başlat
  void _initializePlayers() {
    _player1 = Player(
      id: 'player_1',
      name: gameMode == GameMode.solo ? 'Oyuncu' : 'Oyuncu 1',
      position: PlayerPosition.bottom,
    );
    
    _player2 = Player(
      id: 'player_2',
      name: gameMode == GameMode.solo ? 'Oyuncu' : 'Oyuncu 2',
      position: PlayerPosition.top,
    );
  }
  
  /// Ekran boyutunu ayarla
  void setScreenSize(Size size) {
    if (_screenSize != size) {
      _screenSize = size;
      _initializeArrows();
    }
  }
  
  /// Okları başlat
  void _initializeArrows() {
    if (_screenSize == Size.zero) return;
    
    _bottomArrow = Arrow.create(
      owner: PlayerPosition.bottom,
      screenSize: _screenSize,
    );
    
    // Solo modda sadece alt ok, diğer modlarda her iki ok
    if (gameMode != GameMode.solo) {
      _topArrow = Arrow.create(
        owner: PlayerPosition.top,
        screenSize: _screenSize,
      );
    }
  }
  
  /// Oyunu başlat
  void startGame() {
    _status = GameStatus.countdown;
    notifyListeners();
  }
  
  /// Geri sayım bitti, oyunu başlat
  void onCountdownComplete() {
    _status = GameStatus.playing;
    _remainingTime = GameConstants.gameDurationSeconds;
    _hearts.clear();
    _flyingArrows.clear();
    _player1.reset();
    _player2.reset();
    _initializeArrows();
    _lastHeartSpawn = DateTime.now();
    notifyListeners();
  }
  
  /// Oyunu duraklat
  void pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      notifyListeners();
    }
  }
  
  /// Oyuna devam et
  void resumeGame() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      notifyListeners();
    }
  }
  
  /// Oyunu bitir
  void endGame() {
    _status = GameStatus.finished;
    notifyListeners();
  }
  
  /// Frame sayacı (throttling için)
  int _frameCount = 0;
  static const int _notifyEveryNFrames = 2; // Her 2 frame'de bir bildir
  
  /// Her frame'de çağrılacak güncelleme
  void update(double dt) {
    if (_status != GameStatus.playing) return;
    
    _frameCount++;
    
    // Kalpleri güncelle
    _updateHearts(dt);
    
    // Okları güncelle
    _updateArrows(dt);
    
    // Çarpışma kontrolü
    _checkCollisions();
    
    // Yeni kalp spawn
    _spawnHearts();
    
    // Sadece belirli aralıklarla widget'ı güncelle (performans için)
    if (_frameCount % _notifyEveryNFrames == 0) {
      notifyListeners();
    }
  }
  
  /// Kalpleri güncelle
  void _updateHearts(double dt) {
    for (final heart in _hearts) {
      heart.update(dt, _screenSize);
    }
    
    // Ekran dışına çıkan veya vurulmuş kalpleri temizle
    _hearts.removeWhere((h) => !h.isActive || _isHeartOutOfBounds(h));
  }
  
  /// Kalp ekran dışında mı?
  bool _isHeartOutOfBounds(Heart heart) {
    return heart.position.dy < -heart.size ||
           heart.position.dy > _screenSize.height + heart.size;
  }
  
  /// Okları güncelle
  void _updateArrows(double dt) {
    for (final arrow in _flyingArrows) {
      arrow.update(dt);
    }
    
    // Ekran dışına çıkan okları temizle
    _flyingArrows.removeWhere((a) => a.isOutOfBounds(_screenSize));
  }
  
  /// Çarpışma kontrolü
  void _checkCollisions() {
    final arrowsToRemove = <Arrow>[];
    
    for (final arrow in _flyingArrows) {
      for (final heart in _hearts) {
        if (!heart.isActive) continue;
        
        if (heart.checkCollision(arrow.currentPosition, arrow.hitRadius)) {
          // Kalbi vur
          heart.isActive = false;
          arrowsToRemove.add(arrow);
          
          // Hangi oyuncu vurdu?
          final player = arrow.owner == PlayerPosition.bottom ? _player1 : _player2;
          player.onHeartHit(heart.type, heart.points);
          
          // Efekt callback'lerini çağır
          onHeartHit?.call(heart.position, heart.color);
          onScorePopup?.call(
            (heart.points * player.comboMultiplier).round(),
            heart.position,
          );
          
          if (player.combo >= GameConstants.comboMultiplierThreshold) {
            onCombo?.call(player.combo, player.position);
          }
          
          if (heart.type == HeartType.golden) {
            onScreenShake?.call();
          }
          
          break; // Bir ok sadece bir kalbi vurabilir
        }
      }
    }
    
    _flyingArrows.removeWhere((a) => arrowsToRemove.contains(a));
  }
  
  /// Yeni kalp spawn et
  void _spawnHearts() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastHeartSpawn).inMilliseconds;
    
    if (elapsed >= GameConstants.heartSpawnIntervalMs &&
        _hearts.length < GameConstants.maxHeartsOnScreen) {
      _hearts.add(Heart.spawn(
        screenSize: _screenSize,
        random: _random,
      ));
      _lastHeartSpawn = now;
    }
  }
  
  /// Ok açısını döndür
  void rotateArrow(PlayerPosition player, double deltaAngle) {
    if (_status != GameStatus.playing) return;
    
    final arrow = player == PlayerPosition.bottom ? _bottomArrow : _topArrow;
    arrow?.rotate(deltaAngle);
    notifyListeners();
  }
  
  /// Ok açısını direkt ayarla
  void setArrowAngle(PlayerPosition player, double angle) {
    if (_status != GameStatus.playing) return;
    
    final arrow = player == PlayerPosition.bottom ? _bottomArrow : _topArrow;
    if (arrow != null) {
      // Arrow modelinde setAngle metodu ekleyelim
      arrow.setAngle(angle);
    }
    // Açı değişikliğinde UI güncellenmeli
  }
  
  /// Ok gücünü ayarla
  void setArrowPower(PlayerPosition player, double power) {
    if (_status != GameStatus.playing) return;
    
    final arrow = player == PlayerPosition.bottom ? _bottomArrow : _topArrow;
    arrow?.setPower(power);
    // Güç değişikliğinde UI güncellenmeli ama çok sık çağrıldığı için notifyListeners yok
  }
  
  /// Ok fırlat
  void fireArrow(PlayerPosition player) {
    if (_status != GameStatus.playing) return;
    
    final arrow = player == PlayerPosition.bottom ? _bottomArrow : _topArrow;
    if (arrow == null || arrow.isFlying) return;
    
    // Oyuncu istatistiğini güncelle
    final playerObj = player == PlayerPosition.bottom ? _player1 : _player2;
    playerObj.onArrowFired();
    
    // Oku fırlat
    _flyingArrows.add(arrow.launch());
    
    // Yeni ok oluştur
    if (player == PlayerPosition.bottom) {
      _bottomArrow = Arrow.create(
        owner: PlayerPosition.bottom,
        screenSize: _screenSize,
      );
    } else {
      _topArrow = Arrow.create(
        owner: PlayerPosition.top,
        screenSize: _screenSize,
      );
    }
    
    notifyListeners();
  }
  
  /// Süreyi bir saniye azalt
  void decrementTime() {
    if (_status != GameStatus.playing) return;
    
    _remainingTime--;
    if (_remainingTime <= 0) {
      endGame();
    }
    notifyListeners();
  }
  
  /// Toplam skor (Partners modu için)
  int get totalScore => _player1.score + _player2.score;
  
  /// Kazanan oyuncu (CouplesVs modu için)
  Player? get winner {
    if (_status != GameStatus.finished) return null;
    if (gameMode == GameMode.partners) return null;
    
    if (_player1.score > _player2.score) return _player1;
    if (_player2.score > _player1.score) return _player2;
    return null; // Berabere
  }
  
  /// Oyunu sıfırla
  void reset() {
    _status = GameStatus.waiting;
    _remainingTime = GameConstants.gameDurationSeconds;
    _hearts.clear();
    _flyingArrows.clear();
    _player1.reset();
    _player2.reset();
    _initializeArrows();
    notifyListeners();
  }
  
  /// Oyun sonucu JSON (Firebase için)
  Map<String, dynamic> toResultJson() {
    return {
      'gameMode': gameMode.name,
      'duration': GameConstants.gameDurationSeconds,
      'player1': _player1.toJson(),
      'player2': _player2.toJson(),
      'totalScore': totalScore,
      'winner': winner?.id,
      'playedAt': DateTime.now().toIso8601String(),
    };
  }
}
