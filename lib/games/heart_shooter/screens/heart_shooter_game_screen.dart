import 'package:flutter/material.dart';
import '../heart_shooter.dart';
import '../../../core/constants/app_strings.dart';

/// Ana oyun ekranı
class HeartShooterGameScreen extends StatefulWidget {
  final GameMode gameMode;
  final String? sessionId; // Multiplayer için session ID

  const HeartShooterGameScreen({
    super.key,
    required this.gameMode,
    this.sessionId,
  });

  @override
  State<HeartShooterGameScreen> createState() => _HeartShooterGameScreenState();
}

class _HeartShooterGameScreenState extends State<HeartShooterGameScreen>
    with TickerProviderStateMixin {
  late GameState _gameState;
  late GameEngine _gameEngine;
  late GameEffectsController _effectsController;
  final SoundService _soundService = SoundService();

  // Efekt listeleri
  final List<_ActiveExplosion> _explosions = [];
  final List<_ActiveScorePopup> _scorePopups = [];
  final List<_ActiveComboText> _comboTexts = [];

  int _countdownValue = 3;
  bool _showCountdown = false;
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[HeartShooterGame] initState started');
    
    _effectsController = GameEffectsController();
    _gameState = GameState(gameMode: widget.gameMode);
    debugPrint('[HeartShooterGame] GameState created for mode: ${widget.gameMode}');
    
    // Callback'leri ayarla
    _gameState.onHeartHit = _onHeartHit;
    _gameState.onScorePopup = _onScorePopup;
    _gameState.onCombo = _onCombo;
    _gameState.onScreenShake = _onScreenShake;

    // Motor oluştur
    _gameEngine = GameEngine(gameState: _gameState, vsync: this);
    debugPrint('[HeartShooterGame] GameEngine created');
    
    _gameEngine.onCountdownTick = (count) {
      debugPrint('[HeartShooterGame] Countdown: $count');
      setState(() {
        _countdownValue = count;
        _showCountdown = true;
      });
      _soundService.playCountdown();
    };
    _gameEngine.onGameStart = () {
      debugPrint('[HeartShooterGame] Game started!');
      setState(() => _showCountdown = false);
    };
    _gameEngine.onGameEnd = () {
      debugPrint('[HeartShooterGame] Game ended!');
      setState(() => _showGameOver = true);
      _soundService.playGameOver();
      if (_gameState.winner != null) {
        _soundService.playWin();
      }
    };

    // Ses servisini başlat
    debugPrint('[HeartShooterGame] Initializing sound service...');
    _soundService.initialize().then((_) {
      debugPrint('[HeartShooterGame] Sound service initialized');
    }).catchError((e) {
      debugPrint('[HeartShooterGame] Sound service error: $e');
    });
    
    debugPrint('[HeartShooterGame] initState completed');
  }

  @override
  void dispose() {
    _gameEngine.dispose();
    _gameState.dispose();
    super.dispose();
  }
  
  // Unique ID counters for effects
  static int _explosionIdCounter = 0;
  static int _scorePopupIdCounter = 0;
  static int _comboTextIdCounter = 0;

  void _onHeartHit(Offset position, Color color) {
    _explosionIdCounter++;
    setState(() {
      _explosions.add(_ActiveExplosion(
        id: _explosionIdCounter,
        position: position,
        color: color,
      ));
    });

    // Altın kalp mi kontrol et
    if (color == GameConstants.goldenHeartColor) {
      _soundService.playHitGold();
    } else {
      _soundService.playHitNormal();
    }
  }

  void _onScorePopup(int points, Offset position) {
    _scorePopupIdCounter++;
    setState(() {
      _scorePopups.add(_ActiveScorePopup(
        id: _scorePopupIdCounter,
        points: points,
        position: position,
      ));
    });
  }

  void _onCombo(int combo, PlayerPosition player) {
    _comboTextIdCounter++;
    setState(() {
      _comboTexts.add(_ActiveComboText(
        id: _comboTextIdCounter,
        combo: combo,
        position: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      ));
    });
    _soundService.playCombo();
  }

  void _onScreenShake() {
    _effectsController.triggerScreenShake();
  }

  void _startGame() {
    _gameEngine.start();
  }

  void _restartGame() {
    setState(() {
      _showGameOver = false;
      _explosions.clear();
      _scorePopups.clear();
      _comboTexts.clear();
    });
    _gameEngine.restart();
  }

  void _exitGame() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HeartShooterGame] build called - status: ${_gameState.status}');
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ekran boyutunu ayarla (sadece bir kez)
          if (_gameState.screenSize == Size.zero) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('[HeartShooterGame] Setting screen size: ${constraints.maxWidth}x${constraints.maxHeight}');
              _gameState.setScreenSize(Size(constraints.maxWidth, constraints.maxHeight));
            });
          }

          return GameEffectsWidget(
            controller: _effectsController,
            child: AnimatedBackgroundWidget(
              child: ListenableBuilder(
                listenable: _gameState,
                builder: (context, child) {
                  debugPrint('[HeartShooterGame] ListenableBuilder rebuild - hearts: ${_gameState.hearts.length}, arrows: ${_gameState.flyingArrows.length}');
                  
                  return Stack(
                    children: [
                      // Oyun başlamadıysa başlat butonu
                      if (_gameState.status == GameStatus.waiting)
                        _buildStartScreen(),

                      // Geri sayım
                      if (_showCountdown)
                        CountdownOverlayWidget(count: _countdownValue),

                      // Oyun içeriği
                      if (_gameState.status == GameStatus.playing) ...[
                        // Kalpler
                        ..._buildHearts(),

                        // Uçan oklar
                        ..._buildFlyingArrows(),

                        // Ok kontrolleri
                        _buildArrowControls(),

                        // Skorlar
                        _buildScoreDisplays(),

                        // Süre
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: TimerDisplayWidget(
                              remainingTime: _gameState.remainingTime,
                            ),
                          ),
                        ),

                        // Efektler
                        ..._buildExplosions(),
                        ..._buildScorePopups(),
                        ..._buildComboTexts(),
                      ],

                      // Oyun bitti
                      if (_showGameOver)
                        GameOverOverlayWidget(
                          player1Score: _gameState.player1.score,
                          player2Score: _gameState.player2.score,
                          winnerName: _gameState.winner?.name,
                          gameMode: widget.gameMode,
                          onPlayAgain: _restartGame,
                          onExit: _exitGame,
                        ),

                      // Pause butonu
                      if (_gameState.status == GameStatus.playing)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.pause, color: Colors.white, size: 32),
                            onPressed: () {
                              _gameEngine.pause();
                              _showPauseDialog();
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mod göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.gameMode.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Başlat butonu
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.hsStart,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Geri butonu
          TextButton.icon(
            onPressed: _exitGame,
            icon: const Icon(Icons.arrow_back, color: Colors.white54),
            label: Text(
              AppStrings.hsBack,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHearts() {
    return _gameState.hearts.map((heart) {
      return HeartWidget(
        key: ValueKey(heart.id),
        heart: heart,
      );
    }).toList();
  }

  List<Widget> _buildFlyingArrows() {
    return _gameState.flyingArrows.map((arrow) {
      return FlyingArrowWidget(
        key: ValueKey('arrow_${arrow.id}'),
        arrow: arrow,
      );
    }).toList();
  }

  Widget _buildArrowControls() {
    return Stack(
      children: [
        // Alt ok (her zaman)
        ArrowShooterWidget(
          arrow: _gameState.bottomArrow,
          isTop: false,
          canFire: _gameState.canFireBottom,
          onRotate: (angle) => _gameEngine.setBottomArrowAngle(angle),
          onPowerChange: (power) => _gameEngine.setBottomArrowPower(power),
          onFire: () {
            debugPrint('[HeartShooterGame] Firing bottom arrow');
            _gameEngine.fireBottomArrow();
            _soundService.playShoot();
          },
        ),

        // Üst ok (solo hariç)
        if (widget.gameMode != GameMode.solo)
          ArrowShooterWidget(
            arrow: _gameState.topArrow,
            isTop: true,
            canFire: _gameState.canFireTop,
            onRotate: (angle) => _gameEngine.setTopArrowAngle(angle),
            onPowerChange: (power) => _gameEngine.setTopArrowPower(power),
            onFire: () {
              debugPrint('[HeartShooterGame] Firing top arrow');
              _gameEngine.fireTopArrow();
              _soundService.playShoot();
            },
          ),
      ],
    );
  }

  Widget _buildScoreDisplays() {
    return Stack(
      children: [
        // Oyuncu 1 skoru (alt)
        ScoreDisplayWidget(
          score: _gameState.player1.score,
          combo: _gameState.player1.combo,
          remainingTime: _gameState.remainingTime,
          playerColor: GameConstants.player2Color,
          isTop: false,
          gameMode: widget.gameMode,
        ),

        // Oyuncu 2 skoru (üst) - solo hariç
        if (widget.gameMode != GameMode.solo)
          ScoreDisplayWidget(
            score: _gameState.player2.score,
            combo: _gameState.player2.combo,
            remainingTime: _gameState.remainingTime,
            playerColor: GameConstants.player1Color,
            isTop: true,
            gameMode: widget.gameMode,
          ),
      ],
    );
  }

  List<Widget> _buildExplosions() {
    return _explosions.map((explosion) {
      return HeartExplosionWidget(
        key: ValueKey('explosion_${explosion.id}'),
        position: explosion.position,
        color: explosion.color,
        onComplete: () {
          setState(() {
            _explosions.removeWhere((e) => e.id == explosion.id);
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildScorePopups() {
    return _scorePopups.map((popup) {
      return ScorePopupWidget(
        key: ValueKey('popup_${popup.id}'),
        points: popup.points,
        position: popup.position,
        onComplete: () {
          setState(() {
            _scorePopups.removeWhere((p) => p.id == popup.id);
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildComboTexts() {
    return _comboTexts.map((combo) {
      return ComboTextWidget(
        key: ValueKey('combo_${combo.id}'),
        combo: combo.combo,
        position: combo.position,
        onComplete: () {
          setState(() {
            _comboTexts.removeWhere((c) => c.id == combo.id);
          });
        },
      );
    }).toList();
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppStrings.hsPaused,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameEngine.resume();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppStrings.hsResume),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppStrings.hsRestart),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppStrings.hsExit),
            ),
          ],
        ),
      ),
    );
  }
}

// Aktif efekt modelleri
class _ActiveExplosion {
  final int id;
  final Offset position;
  final Color color;

  _ActiveExplosion({
    required this.id,
    required this.position,
    required this.color,
  });
}

class _ActiveScorePopup {
  final int id;
  final int points;
  final Offset position;

  _ActiveScorePopup({
    required this.id,
    required this.points,
    required this.position,
  });
}

class _ActiveComboText {
  final int id;
  final int combo;
  final Offset position;

  _ActiveComboText({
    required this.id,
    required this.combo,
    required this.position,
  });
}
