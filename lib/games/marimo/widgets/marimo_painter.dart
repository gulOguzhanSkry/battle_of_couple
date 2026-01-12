import 'dart:math';
import 'package:flutter/material.dart';
import '../models/marimo.dart';

/// Marimo'yu çizen özel ressam sınıfı
/// Seviyeye göre boyut, renk ve tüylülük oranını ayarlar
class MarimoPainter extends CustomPainter {
  final MarimoStage stage;
  final bool isSick;
  final bool isDead;
  final double animationValue; // Salınım için (0.0 - 1.0)

  MarimoPainter({
    required this.stage,
    required this.isSick,
    required this.isDead,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isDead) {
      _drawDead(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    // Yarıçapı sahnenin boyutuna göre ayarla
    final radius = min(size.width, size.height) / 2;

    _drawBody(canvas, center, radius);
    _drawHairs(canvas, center, radius);
    _drawFace(canvas, center, radius);
  }

  /// Marimo'nun ana gövdesi
  void _drawBody(Canvas canvas, Offset center, double radius) {
    final colors = isSick
        ? [const Color(0xFFA1887F), const Color(0xFF5D4037)] // Kahverengi tonları
        : [const Color(0xFFAED581), const Color(0xFF33691E)]; // Yeşil tonları

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3), // Işık kaynağı sol üstte
        colors: colors,
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.9, paint); // Tüyler için biraz pay bırak
  }

  /// Yosun tüyleri (Fuzzy effect)
  void _drawHairs(Canvas canvas, Offset center, double radius) {
    final rand = Random(stage.index); // Her aşama için sabit random seed (titreşmemesi için)
    
    // Aşama arttıkça tüy sayısı ve uzunluğu artar
    final int hairCount = 300 + (stage.level * 200); // 500 - 1500 arası
    final double baseHairLength = radius * (0.1 + (stage.level * 0.05)); // %15 - %40 arası uzunluk
    
    final hairPaint = Paint()
      ..color = isSick ? const Color(0xFF8D6E63) : const Color(0xFF558B2F)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < hairCount; i++) {
      // Rastgele açı
      final angle = rand.nextDouble() * 2 * pi;
      
      // Merkezden uzaklık (Yüzeyde ve biraz içinde)
      final dist = (radius * 0.85) + (rand.nextDouble() * radius * 0.15);
      
      // Başlangıç noktası
      final startX = center.dx + cos(angle) * dist;
      final startY = center.dy + sin(angle) * dist;
      
      // Bitiş noktası (Tüyün ucu)
      // Biraz rastgelelik + animasyon etkisi ekleyelim (suda salınım)
      final sway = sin(animationValue * 2 * pi + (startY / 10)) * 5; // Salınım
      
      final length = baseHairLength * (0.8 + rand.nextDouble() * 0.4); // Uzunluk varyasyonu
      final endX = startX + cos(angle) * length + sway;
      final endY = startY + sin(angle) * length;

      // Opaklığı kenarlara doğru azalt (yumuşak geçiş)
      if (rand.nextDouble() > 0.3) { // Her tüyü çizme, biraz boşluk olsun
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), hairPaint);
      }
    }
  }

  /// Sevimli yüz (Gözler)
  void _drawFace(Canvas canvas, Offset center, double radius) {
    if (stage.level < 2) return; // Tohumken yüzü olmasın

    // Gözler
    final eyeOffset = radius * 0.3;
    final eyeY = center.dy - radius * 0.1;
    
    // Gözleri çiz (Büyük siyah daire + küçük beyaz parıltı)
    _drawEye(canvas, Offset(center.dx - eyeOffset, eyeY), radius * 0.15); // Sol
    _drawEye(canvas, Offset(center.dx + eyeOffset, eyeY), radius * 0.15); // Sağ
    
    // Ağız (Hastaysa üzgün, değilse mutlu)
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.2),
      width: radius * 0.2,
      height: radius * 0.2,
    );

    if (isSick) {
      canvas.drawArc(mouthRect, pi + 0.5, pi - 1, false, mouthPaint); // Üzgün
    } else if (stage.level >= 5) {
      // Büyükse kocaman gülümse
      canvas.drawArc(mouthRect, 0.5, pi - 1, false, mouthPaint); 
    } else {
      // Küçükse minik gülümse
      final smallMouthRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.2),
        width: radius * 0.15,
        height: radius * 0.1,
      );
      canvas.drawArc(smallMouthRect, 0.2, pi - 0.4, false, mouthPaint);
    }
  }

  void _drawEye(Canvas canvas, Offset pos, double size) {
    final bgPaint = Paint()..color = Colors.black87;
    final shinePaint = Paint()..color = Colors.white;

    canvas.drawCircle(pos, size, bgPaint);
    canvas.drawCircle(Offset(pos.dx - size * 0.3, pos.dy - size * 0.3), size * 0.3, shinePaint);
  }

  void _drawDead(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Soluk gri gövde
    final paint = Paint()..color = Colors.grey.shade700;
    canvas.drawCircle(center, radius, paint);
    
    // X Gözler
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
      
    final eyeOffset = radius * 0.3;
    final eyeSize = radius * 0.15;
    
    // Sol X
    canvas.drawLine(
      Offset(center.dx - eyeOffset - eyeSize, center.dy - eyeSize),
      Offset(center.dx - eyeOffset + eyeSize, center.dy + eyeSize),
      xPaint,
    );
    canvas.drawLine(
      Offset(center.dx - eyeOffset + eyeSize, center.dy - eyeSize),
      Offset(center.dx - eyeOffset - eyeSize, center.dy + eyeSize),
      xPaint,
    );
    
    // Sağ X
    canvas.drawLine(
      Offset(center.dx + eyeOffset - eyeSize, center.dy - eyeSize),
      Offset(center.dx + eyeOffset + eyeSize, center.dy + eyeSize),
      xPaint,
    );
    canvas.drawLine(
      Offset(center.dx + eyeOffset + eyeSize, center.dy - eyeSize),
      Offset(center.dx + eyeOffset - eyeSize, center.dy + eyeSize),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MarimoPainter oldDelegate) {
    return oldDelegate.stage != stage ||
           oldDelegate.isSick != isSick ||
           oldDelegate.isDead != isDead ||
           oldDelegate.animationValue != animationValue;
  }
}
