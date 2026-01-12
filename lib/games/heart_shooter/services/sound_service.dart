import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../game_constants.dart';

/// Ses yönetim servisi
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _isMuted = false;
  double _volume = 1.0;
  bool _isInitialized = false;

  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isInitialized => _isInitialized;

  /// Servisi başlat ve sesleri önceden yükle
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[SoundService] Already initialized');
      return;
    }
    
    debugPrint('[SoundService] Initializing...');
    
    await _preloadSound(GameConstants.soundShoot);
    await _preloadSound(GameConstants.soundHitNormal);
    await _preloadSound(GameConstants.soundHitGold);
    await _preloadSound(GameConstants.soundCombo);
    await _preloadSound(GameConstants.soundGameOver);
    await _preloadSound(GameConstants.soundCountdown);
    await _preloadSound(GameConstants.soundWin);
    
    _isInitialized = true;
    debugPrint('[SoundService] Initialized with ${_players.length} sounds');
  }

  Future<void> _preloadSound(String path) async {
    try {
      final assetPath = path.replaceFirst('assets/', '');
      debugPrint('[SoundService] Loading: $assetPath');
      
      final player = AudioPlayer();
      await player.setSource(AssetSource(assetPath));
      await player.setVolume(_volume);
      _players[path] = player;
      
      debugPrint('[SoundService] Loaded: $assetPath');
    } catch (e) {
      debugPrint('[SoundService] ERROR loading $path: $e');
    }
  }

  /// Ses çal (Overlapping/Polyphonic support)
  Future<void> play(String soundPath) async {
    if (_isMuted) return;

    try {
      // SFX için her seferinde yeni player oluştur (overlapping için)
      final player = AudioPlayer();
      await player.setVolume(_volume);
      
      // Dosya adını al (assets/ prefixi olmadan)
      final assetPath = soundPath.replaceFirst('assets/', '');
      
      // Çal ve bitince temizle
      await player.play(AssetSource(assetPath));
      
      // Memory leak önlemek için bitince dispose et
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
      
    } catch (e) {
      debugPrint('[SoundService] ERROR playing $soundPath: $e');
    }
  }

  /// Ok atma sesi
  Future<void> playShoot() => play(GameConstants.soundShoot);

  /// Normal kalp vuruş sesi
  Future<void> playHitNormal() => play(GameConstants.soundHitNormal);

  /// Altın kalp vuruş sesi
  Future<void> playHitGold() => play(GameConstants.soundHitGold);

  /// Combo sesi
  Future<void> playCombo() => play(GameConstants.soundCombo);

  /// Oyun sonu sesi
  Future<void> playGameOver() => play(GameConstants.soundGameOver);

  /// Geri sayım sesi
  Future<void> playCountdown() => play(GameConstants.soundCountdown);

  /// Kazanma sesi
  Future<void> playWin() => play(GameConstants.soundWin);

  /// Sesi kapat/aç
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// Sesi kapat
  void mute() {
    _isMuted = true;
  }

  /// Sesi aç
  void unmute() {
    _isMuted = false;
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Tüm sesleri durdur (bunu yapmak zor artık çünkü referans tutmuyoruz, ama SFX zaten kısa)
  Future<void> stopAll() async {
    // SFX'ler kısa olduğu için genellikle durdurmaya gerek yok
    // Ama eğer müzik eklenirse buraya mantık eklenebilir
  }

  /// Servisi temizle
  Future<void> dispose() async {
    // Active players listesi tutulursa burada dispose edilebilir
  }
}
