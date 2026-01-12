import 'dart:math';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../models/arrow.dart';

/// Ok atış kontrol widget'ı
/// Kullanıcı dokunarak oku yönlendirir, basılı tutarak gücü artırır, bırakınca fırlatır
class ArrowShooterWidget extends StatefulWidget {
  final Arrow? arrow;
  final bool isTop;
  final bool canFire; // Ok ekrandan çıktı mı kontrolü
  final Function(double) onRotate; // Açı değişikliği
  final Function(double) onPowerChange; // Güç değişikliği
  final VoidCallback onFire;

  const ArrowShooterWidget({
    super.key,
    required this.arrow,
    required this.isTop,
    this.canFire = true,
    required this.onRotate,
    required this.onPowerChange,
    required this.onFire,
  });

  @override
  State<ArrowShooterWidget> createState() => _ArrowShooterWidgetState();
}

class _ArrowShooterWidgetState extends State<ArrowShooterWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _chargeController;
  
  bool _isCharging = false;
  Offset? _touchPosition;
  double _currentPower = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _chargeController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Max 2 saniye şarj
      vsync: this,
    );
    
    _chargeController.addListener(() {
      if (_isCharging) {
        setState(() {
          _currentPower = _chargeController.value;
        });
        widget.onPowerChange(_currentPower);
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  void _handleTouchStart(Offset globalPosition, Offset localPosition) {
    if (!widget.canFire || widget.arrow == null) {
      debugPrint('[ArrowShooter] Cannot fire - canFire: ${widget.canFire}, arrow: ${widget.arrow != null}');
      return;
    }
    
    debugPrint('[ArrowShooter] Touch start at: $localPosition');
    
    setState(() {
      _isCharging = true;
      _touchPosition = localPosition;
    });
    
    // Güç şarjını başlat
    _chargeController.forward(from: 0);
    
    // Ok yönünü hesapla ve güncelle
    _updateArrowAngle(localPosition);
  }

  void _handleTouchUpdate(Offset globalPosition, Offset localPosition) {
    if (!_isCharging || widget.arrow == null) return;
    
    setState(() {
      _touchPosition = localPosition;
    });
    
    // Ok yönünü güncelle
    _updateArrowAngle(localPosition);
  }

  void _handleTouchEnd() {
    if (!_isCharging || widget.arrow == null) return;
    
    debugPrint('[ArrowShooter] Touch end - power: $_currentPower');
    
    // Şarjı durdur
    _chargeController.stop();
    
    // Minimum güç varsa fırlat
    if (_currentPower > 0.1) {
      debugPrint('[ArrowShooter] Firing arrow with power: $_currentPower');
      widget.onFire();
    } else {
      debugPrint('[ArrowShooter] Power too low, not firing');
    }
    
    // Sıfırla
    setState(() {
      _isCharging = false;
      _touchPosition = null;
      _currentPower = 0;
    });
    
    widget.onPowerChange(0);
  }
  
  void _updateArrowAngle(Offset touchPosition) {
    if (widget.arrow == null) return;
    
    // Ok başlangıç noktası (ekranın ortası)
    final screenWidth = MediaQuery.of(context).size.width;
    final arrowCenter = Offset(screenWidth / 2, 60); // Ok merkezi
    
    // Touch pozisyonundan oka doğru vektör
    final dx = touchPosition.dx - arrowCenter.dx;
    final dy = widget.isTop 
        ? touchPosition.dy - arrowCenter.dy 
        : arrowCenter.dy - touchPosition.dy;
    
    // Açıyı hesapla
    double angle = atan2(dy.abs(), dx);
    
    // Açıyı sınırla (0 ile pi arası)
    angle = angle.clamp(0.1, pi - 0.1);
    
    // Ok yönünü güncelle
    widget.onRotate(angle);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arrow == null) return const SizedBox.shrink();

    final arrow = widget.arrow!;
    final color = arrow.owner.color;
    final canFireNow = widget.canFire;

    return Positioned(
      left: 0,
      right: 0,
      top: widget.isTop ? 0 : null,
      bottom: widget.isTop ? null : 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _handleTouchStart(
          details.globalPosition, 
          details.localPosition,
        ),
        onPanUpdate: (details) => _handleTouchUpdate(
          details.globalPosition,
          details.localPosition,
        ),
        onPanEnd: (_) => _handleTouchEnd(),
        onPanCancel: _handleTouchEnd,
        child: Container(
          height: 150,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dokunma alanı göstergesi
              if (!canFireNow)
                _buildCooldownIndicator(color),
              
              // Arka plan göstergesi
              if (canFireNow)
                _buildBackgroundIndicator(color),
              
              // Nişan çizgisi (dokunurken)
              if (_isCharging && _touchPosition != null)
                _buildAimLine(color),
              
              // Ok (geri çekilir)
              _buildArrow(arrow, color),
              
              // Güç göstergesi
              if (_currentPower > 0)
                _buildPowerIndicator(_currentPower, color),
              
              // Güç yüzdesi
              if (_isCharging)
                _buildPowerText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCooldownIndicator(Color color) {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.timer,
          color: Colors.grey.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBackgroundIndicator(Color color) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: color.withOpacity(_isCharging ? 0.6 : 0.2 + _glowController.value * 0.2),
              width: _isCharging ? 3 : 2,
            ),
            gradient: RadialGradient(
              colors: [
                color.withOpacity(_isCharging ? 0.3 : 0.1 + _glowController.value * 0.1),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAimLine(Color color) {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: AimLinePainter(
        touchPosition: _touchPosition!,
        isTop: widget.isTop,
        color: color.withOpacity(0.5),
      ),
    );
  }

  Widget _buildArrow(Arrow arrow, Color color) {
    // Ok yönü
    final rotationAngle = widget.isTop 
        ? arrow.angle - pi / 2
        : -(arrow.angle - pi / 2);
    
    // Güce göre geri çekilme miktarı
    final pullBack = _currentPower * 30; // Max 30 piksel geri çekme
    
    return Transform.translate(
      offset: Offset(
        0, 
        widget.isTop ? pullBack : -pullBack,
      ),
      child: Transform.rotate(
        angle: rotationAngle,
        child: Container(
          width: GameConstants.arrowLength * (1 + _currentPower * 0.2),
          height: GameConstants.arrowWidth * 2,
          child: CustomPaint(
            painter: ArrowPainter(
              color: color,
              power: _currentPower,
              isCharging: _isCharging,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerIndicator(double power, Color color) {
    return Positioned(
      bottom: widget.isTop ? null : 130,
      top: widget.isTop ? 130 : null,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 120,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.black38,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: power,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    power > 0.5 ? Colors.yellow : Colors.green,
                    power > 0.8 ? Colors.red : Colors.yellow,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (power > 0.8 ? Colors.red : Colors.green).withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPowerText() {
    final percentage = (_currentPower * 100).toInt();
    return Positioned(
      bottom: widget.isTop ? null : 105,
      top: widget.isTop ? 105 : null,
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nişan çizgisi painter
class AimLinePainter extends CustomPainter {
  final Offset touchPosition;
  final bool isTop;
  final Color color;

  AimLinePainter({
    required this.touchPosition,
    required this.isTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Kesikli çizgi
    final dashWidth = 8.0;
    final dashSpace = 4.0;
    
    final center = Offset(size.width / 2, isTop ? 60 : size.height - 60);
    final target = touchPosition;
    
    final distance = (target - center).distance;
    final dx = (target.dx - center.dx) / distance;
    final dy = (target.dy - center.dy) / distance;
    
    double drawn = 0;
    while (drawn < distance) {
      final start = Offset(center.dx + dx * drawn, center.dy + dy * drawn);
      final end = Offset(
        center.dx + dx * min(drawn + dashWidth, distance),
        center.dy + dy * min(drawn + dashWidth, distance),
      );
      canvas.drawLine(start, end, paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant AimLinePainter oldDelegate) {
    return touchPosition != oldDelegate.touchPosition;
  }
}

/// Ok şeklini çizen painter
class ArrowPainter extends CustomPainter {
  final Color color;
  final double power;
  final bool isCharging;

  ArrowPainter({
    required this.color,
    required this.power,
    required this.isCharging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.8),
          color,
          isCharging ? Colors.white : color,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Ok gövdesi
    final bodyPath = Path();
    final bodyWidth = size.height * 0.4;
    final bodyStart = size.width * 0.3;
    
    bodyPath.moveTo(0, size.height / 2 - bodyWidth / 2);
    bodyPath.lineTo(bodyStart, size.height / 2 - bodyWidth / 2);
    bodyPath.lineTo(bodyStart, size.height / 2 + bodyWidth / 2);
    bodyPath.lineTo(0, size.height / 2 + bodyWidth / 2);
    bodyPath.close();

    // Ok başı (üçgen)
    final headPath = Path();
    headPath.moveTo(bodyStart, 0);
    headPath.lineTo(size.width, size.height / 2);
    headPath.lineTo(bodyStart, size.height);
    headPath.close();

    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(headPath, paint);

    // Parlama efekti
    if (isCharging && power > 0.3) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + power * 2
        ..color = Colors.white.withOpacity(0.3 + power * 0.4);
      
      canvas.drawPath(headPath, glowPaint);
    }

    // Glow efekti
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8)
      ..color = color.withOpacity(0.3 + power * 0.4);
    
    canvas.drawPath(headPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return color != oldDelegate.color ||
           power != oldDelegate.power ||
           isCharging != oldDelegate.isCharging;
  }
}

/// Uçan ok widget'ı
class FlyingArrowWidget extends StatelessWidget {
  final Arrow arrow;

  const FlyingArrowWidget({
    super.key,
    required this.arrow,
  });

  @override
  Widget build(BuildContext context) {
    if (!arrow.isFlying) return const SizedBox.shrink();

    final color = arrow.owner.color;
    final rotationAngle = arrow.owner == PlayerPosition.bottom
        ? -(arrow.angle - pi / 2)
        : arrow.angle - pi / 2;

    return Positioned(
      left: arrow.currentPosition.dx - GameConstants.arrowLength / 2,
      top: arrow.currentPosition.dy - GameConstants.arrowWidth,
      child: Transform.rotate(
        angle: rotationAngle,
        child: Container(
          width: GameConstants.arrowLength,
          height: GameConstants.arrowWidth * 2,
          child: CustomPaint(
            painter: ArrowPainter(
              color: color,
              power: 1.0,
              isCharging: false,
            ),
          ),
        ),
      ),
    );
  }
}
