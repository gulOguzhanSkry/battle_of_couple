import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays a heart confetti animation starting from a specific point.
class CustomHeartConfetti extends StatefulWidget {
  final bool isPlaying;
  final Duration duration;
  final Offset? spawnPosition; // Position to spawn hearts from

  const CustomHeartConfetti({
    super.key,
    required this.isPlaying,
    this.duration = const Duration(seconds: 1), // Shorter duration per burst
    this.spawnPosition,
  });

  @override
  State<CustomHeartConfetti> createState() => _CustomHeartConfettiState();
}

class _CustomHeartConfettiState extends State<CustomHeartConfetti> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(_updateParticles);
    
    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(CustomHeartConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _particles.clear();
    // Use widget.spawnPosition if provided, otherwise default to top center
    final startPos = widget.spawnPosition ?? const Offset(200, -50); 
    
    // Generate particles
    for (int i = 0; i < 20; i++) {
       // Spread them slightly around the touch point
      _particles.add(_HeartParticle.random(_random, startPos));
    }
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HeartConfettiPainter(particles: _particles),
      ),
    );
  }
}

/// Represents a single heart particle with physics properties.
class _HeartParticle {
  Offset position;
  Offset velocity;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;
  double opacity = 1.0;

  _HeartParticle({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });

  factory _HeartParticle.random(math.Random random, Offset origin) {
    return _HeartParticle(
      position: origin + Offset(
        (random.nextDouble() - 0.5) * 50, // Slight horizontal spread 
        (random.nextDouble() - 0.5) * 50, // Slight vertical spread
      ),
      velocity: Offset(
        (random.nextDouble() - 0.5) * 4, // Explode outward horizontally
        -random.nextDouble() * 5 - 2, // Explode UPWARD initially
      ),
      rotation: random.nextDouble() * math.pi * 2,
      rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      color: Colors.pinkAccent.withOpacity(random.nextDouble() * 0.5 + 0.5),
      size: random.nextDouble() * 10 + 5, // Smaller particles for finger effect
    );
  }

  void update() {
    position += velocity;
    rotation += rotationSpeed;
    velocity += const Offset(0, 0.2); // Gravity pulls them down
    opacity -= 0.02; // Fade out faster
    if (opacity < 0) opacity = 0;
  }
}

class _HeartConfettiPainter extends CustomPainter {
  final List<_HeartParticle> particles;

  _HeartConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      // Use absolute coordinates since we are passing global header offsets now ideally
      // But purely for safety, we just draw at particle position.
      // Adjust for AppBar/StatusBar offset roughly (approx 80-100px usually) to align with finger visually
      // since CustomPaint is in body but coords are global.
      final dx = particle.position.dx;
      final dy = particle.position.dy - 80; 

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotation);

      // Draw Heart
      final path = Path();
      final width = particle.size;
      final height = particle.size;
      
      path.moveTo(0, height * 0.35);
      path.cubicTo(
        -width * 0.5, -height * 0.2, 
        -width, height * 0.4, 
        0, height
      ); // Left curve
      path.moveTo(0, height * 0.35);
      path.cubicTo(
        width * 0.5, -height * 0.2, 
        width, height * 0.4, 
        0, height
      ); // Right curve

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HeartConfettiPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
