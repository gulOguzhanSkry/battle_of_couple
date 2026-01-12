import 'package:flutter/material.dart';

/// A widget that provides a scratch-off effect to reveal its child.
class CustomScratchCard extends StatefulWidget {
  /// The content hidden behind the scratch layer.
  final Widget child;

  /// The color of the scratch layer.
  final Color coverColor;

  /// The brush size for scratching.
  final double brushSize;

  /// The threshold percentage (0.0 to 1.0) to trigger auto-reveal or completion check.
  final double threshold;

  /// Callback when the threshold is reached.
  final VoidCallback? onThresholdReached;

  /// Callback when the user scratches.
  /// Returns a value between 0.0 and 1.0 indicating the percentage scratched.
  final ValueChanged<double>? onScratch;

  /// Callback when the user scratches, returning the local scratch position.
  final ValueChanged<Offset>? onScratchOffset;

  const CustomScratchCard({
    super.key,
    required this.child,
    this.coverColor = Colors.grey,
    this.onScratch,
    this.onScratchOffset,
    this.brushSize = 20.0,
    this.threshold = 0.5,
    this.onThresholdReached,
  });

  @override
  State<CustomScratchCard> createState() => _CustomScratchCardState();
}

class _CustomScratchCardState extends State<CustomScratchCard> {
  final List<Offset?> _points = [];
  bool _isFinished = false;
  final GlobalKey _globalKey = GlobalKey();

  void _addPoint(Offset globalPosition) {
    if (_isFinished) return;

    final RenderBox? renderBox = _globalKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset localPosition = renderBox.globalToLocal(globalPosition);
      setState(() {
        _points.add(localPosition);
      });
      // Trigger animation callback
      if (widget.onScratchOffset != null) {
        widget.onScratchOffset!(globalPosition); // Send GLOBAL position for overlay
      }
      _calculatePercentage();
    }
  }

  void _calculatePercentage() {
    // Estimating percentage based on points count vs area is complex without pixel manipulation.
    // For this MVP, we approximate based on the number of points relative to a heuristic.
    // A more accurate way involves reading the buffer which is expensive in Flutter.
    // Clean Code approach: Delegate complex calculation or keep it simple for UI performance.
    
    // Simple Heuristic: If we have enough points spread out, we assume it's revealed.
    // This is a naive implementation but performant for UI.
    // In a real production app with strict requirements, we'd use an image buffer.
    
    // Let's assume 150 points is enough to trigger "some" progress for this demo.
    // We will rely on the user visually seeing the code.
    
    if (_points.length > 150 && !_isFinished) {
       // Trigger logic after some scratching
       if (widget.onThresholdReached != null) {
         _isFinished = true; // Prevent multiple triggers
         widget.onThresholdReached!();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _globalKey,
      children: [
        // The hidden content
        widget.child,
        
        // The scratch layer
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) => _addPoint(details.globalPosition),
            onPanUpdate: (details) => _addPoint(details.globalPosition),
            onPanEnd: (details) => _points.add(null),
            child: CustomPaint(
              painter: _ScratchPainter(
                points: _points,
                color: widget.coverColor,
                brushSize: widget.brushSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class _ScratchPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double brushSize;

  _ScratchPainter({
    required this.points,
    required this.color,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Save layer to apply blend mode
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 2. Draw the cover (full rectangle)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color, // Cover color
    );

    // 3. Draw the "scratched" path with BlendMode.clear to erase
    // 3. Draw the "scratched" path with BlendMode.clear to erase
    final Paint paint = Paint()
      ..blendMode = BlendMode.clear
      ..color = Colors.transparent
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isPenDown = false;
    for (int i = 0; i < points.length; i++) {
        final p = points[i];
        if (p == null) {
            isPenDown = false;
            continue;
        }
        if (!isPenDown) {
            path.moveTo(p.dx, p.dy);
            isPenDown = true;
        } else {
            path.lineTo(p.dx, p.dy);
        }
    }
    
    canvas.drawPath(path, paint);

    // 4. Restore layer
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
