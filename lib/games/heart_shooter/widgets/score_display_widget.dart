import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Skor gösterge widget'ı
class ScoreDisplayWidget extends StatelessWidget {
  final int score;
  final int combo;
  final int remainingTime;
  final Color playerColor;
  final bool isTop;
  final GameMode gameMode;

  const ScoreDisplayWidget({
    super.key,
    required this.score,
    required this.combo,
    required this.remainingTime,
    required this.playerColor,
    required this.isTop,
    required this.gameMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? 50 : null,
      bottom: isTop ? null : 140,
      left: isTop ? 16 : null,
      right: isTop ? null : 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: playerColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: playerColor.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skor
            _ScoreNumber(score: score, color: playerColor),
            
            // Combo badge
            if (combo >= GameConstants.comboMultiplierThreshold) ...[
              const SizedBox(width: 8),
              _ComboBadge(combo: combo),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreNumber extends StatefulWidget {
  final int score;
  final Color color;

  const _ScoreNumber({
    required this.score,
    required this.color,
  });

  @override
  State<_ScoreNumber> createState() => _ScoreNumberState();
}

class _ScoreNumberState extends State<_ScoreNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _displayScore = widget.score;
  }

  @override
  void didUpdateWidget(_ScoreNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      _animateScore(oldWidget.score, widget.score);
    }
  }

  void _animateScore(int from, int to) {
    _controller.reset();
    _controller.forward();

    _controller.addListener(() {
      setState(() {
        _displayScore = (from + (to - from) * _controller.value).round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _controller.isAnimating ? 1.2 : 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Text(
            '$_displayScore',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: widget.color,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ComboBadge extends StatefulWidget {
  final int combo;

  const _ComboBadge({required this.combo});

  @override
  State<_ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<_ComboBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
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
        return Transform.scale(
          scale: 1.0 + _controller.value * 0.1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.red,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5 + _controller.value * 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              '${widget.combo}x',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Süre göstergesi widget'ı
class TimerDisplayWidget extends StatelessWidget {
  final int remainingTime;

  const TimerDisplayWidget({
    super.key,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = remainingTime <= 10;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.withOpacity(0.8) : Colors.black54,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isLowTime ? Colors.red : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: isLowTime ? 1.2 : 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Text(
                  _formatTime(remainingTime),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Skor popup widget'ı (kalp vurulunca çıkan)
class ScorePopupWidget extends StatefulWidget {
  final int points;
  final Offset position;
  final VoidCallback onComplete;

  const ScorePopupWidget({
    super.key,
    required this.points,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ScorePopupWidget> createState() => _ScorePopupWidgetState();
}

class _ScorePopupWidgetState extends State<ScorePopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: GameConstants.scorePopupDurationMs),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0),
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -50),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) => widget.onComplete());
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
        return Positioned(
          left: widget.position.dx - 30,
          top: widget.position.dy + _positionAnimation.value.dy - 20,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber,
                      Colors.orange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.points}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Combo yazısı widget'ı
class ComboTextWidget extends StatefulWidget {
  final int combo;
  final Offset position;
  final VoidCallback onComplete;

  const ComboTextWidget({
    super.key,
    required this.combo,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ComboTextWidget> createState() => _ComboTextWidgetState();
}

class _ComboTextWidgetState extends State<ComboTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: GameConstants.comboDurationMs),
      vsync: this,
    );

    _controller.forward().then((_) => widget.onComplete());
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
        final scale = 1.0 + sin(_controller.value * pi) * 0.5;
        final opacity = 1.0 - _controller.value;

        return Positioned(
          left: widget.position.dx - 60,
          top: widget.position.dy - 30,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple,
                      Colors.deepPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.combo}x COMBO!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
