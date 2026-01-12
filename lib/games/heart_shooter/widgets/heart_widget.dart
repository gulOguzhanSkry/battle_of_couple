import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/heart.dart';

/// Kalp widget'ı - animasyonlu pulse efektli
class HeartWidget extends StatelessWidget {
  final Heart heart;
  final VoidCallback? onHit;

  const HeartWidget({
    super.key,
    required this.heart,
    this.onHit,
  });

  @override
  Widget build(BuildContext context) {
    if (!heart.isActive) return const SizedBox.shrink();

    return Positioned(
      left: heart.position.dx - heart.size / 2,
      top: heart.position.dy - heart.size / 2,
      child: Transform.scale(
        scale: heart.pulseScale,
        child: _buildHeart(),
      ),
    );
  }

  Widget _buildHeart() {
    return Container(
      width: heart.size,
      height: heart.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: heart.color.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: heart.color.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(heart.size, heart.size),
        painter: HeartPainter(
          color: heart.color,
          type: heart.type,
        ),
      ),
    );
  }
}

/// Kalp şeklini çizen painter
class HeartPainter extends CustomPainter {
  final Color color;
  final HeartType type;

  HeartPainter({
    required this.color,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Gradient dolgu
    if (type == HeartType.golden) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFE066),
          const Color(0xFFFFD700),
          const Color(0xFFDAA520),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else if (type == HeartType.bonus) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE040FB),
          const Color(0xFF9C27B0),
          const Color(0xFF7B1FA2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF6B9D),
          const Color(0xFFE91E63),
          const Color(0xFFC2185B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // Kalp şekli path
    final path = _createHeartPath(size);
    canvas.drawPath(path, paint);

    // Parlak efekti (highlight)
    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.3);
    
    final highlightPath = Path()
      ..addOval(Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.15,
        size.width * 0.25,
        size.height * 0.2,
      ));
    canvas.drawPath(highlightPath, highlightPaint);

    // Altın kalp için yıldız efekti
    if (type == HeartType.golden) {
      _drawSparkles(canvas, size);
    }
  }

  Path _createHeartPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, h * 0.85);
    
    // Sol taraf
    path.cubicTo(
      w * 0.1, h * 0.6,
      w * 0.1, h * 0.25,
      w / 2, h * 0.25,
    );
    
    // Sağ taraf
    path.cubicTo(
      w * 0.9, h * 0.25,
      w * 0.9, h * 0.6,
      w / 2, h * 0.85,
    );

    path.close();
    return path;
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = Random(42); // Sabit seed ile tutarlı sparkle pozisyonları
    
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6 + size.height * 0.1;
      final sparkleSize = 2.0 + random.nextDouble() * 2;
      
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize,
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) {
    return color != oldDelegate.color || type != oldDelegate.type;
  }
}

/// Kalp patlama efekti widget'ı
class HeartExplosionWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const HeartExplosionWidget({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<HeartExplosionWidget> createState() => _HeartExplosionWidgetState();
}

class _HeartExplosionWidgetState extends State<HeartExplosionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: GameConstants.explosionDurationMs),
      vsync: this,
    );

    _particles = _generateParticles();

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  List<_Particle> _generateParticles() {
    final random = Random();
    return List.generate(GameConstants.particleCount, (index) {
      final angle = (index / GameConstants.particleCount) * 2 * pi;
      final speed = GameConstants.particleMinSpeed +
          random.nextDouble() * (GameConstants.particleMaxSpeed - GameConstants.particleMinSpeed);
      final size = GameConstants.particleMinSize +
          random.nextDouble() * (GameConstants.particleMaxSize - GameConstants.particleMinSize);

      return _Particle(
        angle: angle + (random.nextDouble() - 0.5) * 0.5,
        speed: speed,
        size: size,
        color: widget.color.withOpacity(0.8 + random.nextDouble() * 0.2),
      );
    });
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
        return CustomPaint(
          size: Size.infinite,
          painter: _ExplosionPainter(
            center: widget.position,
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ExplosionPainter extends CustomPainter {
  final Offset center;
  final List<_Particle> particles;
  final double progress;

  _ExplosionPainter({
    required this.center,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final distance = particle.speed * progress;
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      final opacity = (1 - progress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1 - progress * 0.5);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Mini kalp şekli için
      _drawMiniHeart(canvas, Offset(x, y), currentSize, paint);
    }
  }

  void _drawMiniHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size;
    final x = center.dx - w / 2;
    final y = center.dy - h / 2;

    path.moveTo(x + w / 2, y + h * 0.85);
    path.cubicTo(x + w * 0.1, y + h * 0.6, x + w * 0.1, y + h * 0.25, x + w / 2, y + h * 0.25);
    path.cubicTo(x + w * 0.9, y + h * 0.25, x + w * 0.9, y + h * 0.6, x + w / 2, y + h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
