import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Oyun efektleri yönetici sınıfı
/// Ekran titremesi, parçacık efektleri vb.
class GameEffectsWidget extends StatefulWidget {
  final Widget child;
  final GameEffectsController controller;

  const GameEffectsWidget({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<GameEffectsWidget> createState() => _GameEffectsWidgetState();
}

class _GameEffectsWidgetState extends State<GameEffectsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: Duration(milliseconds: GameConstants.screenShakeDurationMs),
      vsync: this,
    );

    widget.controller._setState(this);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offsetX = 0;
        double offsetY = 0;

        if (_shakeController.isAnimating) {
          final intensity = (1 - _shakeController.value) * 8;
          offsetX = (_random.nextDouble() - 0.5) * intensity;
          offsetY = (_random.nextDouble() - 0.5) * intensity;
        }

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: widget.child,
        );
      },
    );
  }
}

/// Efekt controller - dışarıdan efektleri tetiklemek için
class GameEffectsController {
  _GameEffectsWidgetState? _state;

  void _setState(_GameEffectsWidgetState state) {
    _state = state;
  }

  void triggerScreenShake() {
    _state?._triggerShake();
  }
}

/// Arka plan animasyonlu gradient widget'ı
class AnimatedBackgroundWidget extends StatefulWidget {
  final Widget child;

  const AnimatedBackgroundWidget({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackgroundWidget> createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: GameConstants.backgroundGradient,
              transform: GradientRotation(_controller.value * 2 * pi * 0.1),
            ),
          ),
          child: Stack(
            children: [
              // Yıldız parçacıkları
              ...List.generate(20, (index) {
                return _StarParticle(
                  controller: _controller,
                  index: index,
                );
              }),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _StarParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _StarParticle({
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    final size = MediaQuery.of(context).size;
    
    final x = random.nextDouble() * size.width;
    final baseY = random.nextDouble() * size.height;
    final starSize = 1.0 + random.nextDouble() * 2;
    final speed = 0.5 + random.nextDouble() * 0.5;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final phase = (controller.value * speed + index / 20) % 1.0;
        final y = (baseY + phase * 100) % size.height;
        final opacity = (sin(phase * pi * 2) * 0.5 + 0.5).clamp(0.1, 0.6);

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: starSize,
            height: starSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Geri sayım overlay widget'ı
class CountdownOverlayWidget extends StatefulWidget {
  final int count;
  final VoidCallback? onComplete;

  const CountdownOverlayWidget({
    super.key,
    required this.count,
    this.onComplete,
  });

  @override
  State<CountdownOverlayWidget> createState() => _CountdownOverlayWidgetState();
}

class _CountdownOverlayWidgetState extends State<CountdownOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountdownOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + (1 - _controller.value) * 2;
            final opacity = (1 - _controller.value * 0.5).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: _buildCountText(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountText() {
    final text = widget.count > 0 ? '${widget.count}' : 'BAŞLA!';
    final color = widget.count > 0 ? Colors.white : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: widget.count > 0 ? 120 : 60,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [
            Shadow(
              color: color,
              blurRadius: 30,
            ),
            Shadow(
              color: color.withOpacity(0.5),
              blurRadius: 60,
            ),
          ],
        ),
      ),
    );
  }
}

/// Oyun sonu overlay widget'ı
class GameOverOverlayWidget extends StatefulWidget {
  final int player1Score;
  final int player2Score;
  final String? winnerName;
  final GameMode gameMode;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameOverOverlayWidget({
    super.key,
    required this.player1Score,
    required this.player2Score,
    this.winnerName,
    required this.gameMode,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<GameOverOverlayWidget> createState() => _GameOverOverlayWidgetState();
}

class _GameOverOverlayWidgetState extends State<GameOverOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * _controller.value),
          child: Center(
            child: Transform.scale(
              scale: _controller.value,
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final totalScore = widget.player1Score + widget.player2Score;
    
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.purple.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Text(
            'OYUN BİTTİ!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.purple,
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Kazanan veya toplam skor
          if (widget.gameMode == GameMode.partners) ...[
            _buildPartnerScore(totalScore),
          ] else if (widget.winnerName != null) ...[
            _buildWinnerDisplay(),
          ] else ...[
            _buildDrawDisplay(),
          ],
          
          const SizedBox(height: 24),
          
          // Skorlar
          if (widget.gameMode != GameMode.solo)
            _buildScoreComparison(),
          
          const SizedBox(height: 32),
          
          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                'Tekrar Oyna',
                Colors.green,
                widget.onPlayAgain,
              ),
              const SizedBox(width: 16),
              _buildButton(
                'Çıkış',
                Colors.red,
                widget.onExit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerScore(int totalScore) {
    return Column(
      children: [
        const Text(
          'TOPLAM SKOR',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$totalScore',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerDisplay() {
    return Column(
      children: [
        const Text(
          '🏆 KAZANAN 🏆',
          style: TextStyle(
            fontSize: 20,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.winnerName!,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawDisplay() {
    return const Text(
      '🤝 BERABERE 🤝',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildScoreComparison() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlayerScore('Oyuncu 1', widget.player1Score, GameConstants.player1Color),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
        ),
        _buildPlayerScore('Oyuncu 2', widget.player2Score, GameConstants.player2Color),
      ],
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
