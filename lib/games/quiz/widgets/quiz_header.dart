import 'package:flutter/material.dart';

/// Animasyonlu Quiz header - Timer ve skor gösterimi
/// Doğru cevaplarda puan artış animasyonu gösterir
class QuizHeader extends StatefulWidget {
  final int remainingSeconds;
  final int score;
  final int correctCount;
  final Animation<double> pulseAnimation;
  final VoidCallback onExit;

  const QuizHeader({
    super.key,
    required this.remainingSeconds,
    required this.score,
    required this.correctCount,
    required this.pulseAnimation,
    required this.onExit,
  });

  @override
  State<QuizHeader> createState() => _QuizHeaderState();
}

class _QuizHeaderState extends State<QuizHeader> with SingleTickerProviderStateMixin {
  AnimationController? _floatingController;
  
  int _previousScore = 0;
  bool _showFloatingScore = false;
  int _addedPoints = 0;
  double _scaleValue = 1.0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _initAnimationController();
  }
  
  /// Animation controller'ı güvenli şekilde başlat
  void _initAnimationController() {
    try {
      _floatingController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _floatingController?.addStatusListener(_onAnimationStatusChanged);
    } catch (e) {
      debugPrint('[QuizHeader] Animation controller init error: $e');
      // Animasyon olmadan devam et - graceful degradation
    }
  }
  
  /// Animasyon durumu değişiklik handler'ı
  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _showFloatingScore = false);
      _floatingController?.reset();
    }
  }

  @override
  void didUpdateWidget(QuizHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Skor arttıysa animasyon başlat
    if (widget.score > _previousScore) {
      _addedPoints = widget.score - _previousScore;
      _previousScore = widget.score;
      
      _playScoreBounceAnimation();
      _playFloatingTextAnimation();
    }
  }
  
  /// Skor bounce animasyonunu güvenli şekilde çalıştır
  Future<void> _playScoreBounceAnimation() async {
    try {
      if (!mounted) return;
      setState(() => _scaleValue = 1.3);
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      if (!mounted) return;
      setState(() => _scaleValue = 1.0);
    } catch (e) {
      // Animasyon hatası - sessizce devam et
      debugPrint('[QuizHeader] Scale animation error: $e');
      if (mounted) {
        setState(() => _scaleValue = 1.0);
      }
    }
  }
  
  /// Floating +10 animasyonunu güvenli şekilde başlat
  void _playFloatingTextAnimation() {
    try {
      if (!mounted || _floatingController == null) return;
      
      setState(() => _showFloatingScore = true);
      _floatingController?.forward(from: 0);
    } catch (e) {
      debugPrint('[QuizHeader] Floating animation error: $e');
      // Hata durumunda floating'i gizle
      if (mounted) {
        setState(() => _showFloatingScore = false);
      }
    }
  }

  @override
  void dispose() {
    try {
      _floatingController?.removeStatusListener(_onAnimationStatusChanged);
      _floatingController?.dispose();
    } catch (e) {
      debugPrint('[QuizHeader] Dispose error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onExit,
            icon: const Icon(Icons.close, color: Colors.white54, size: 28),
          ),
          const Spacer(),
          _buildTimerWidget(),
          const Spacer(),
          _buildScoreWidget(),
        ],
      ),
    );
  }
  
  /// Timer widget'ı
  Widget _buildTimerWidget() {
    return AnimatedBuilder(
      animation: widget.pulseAnimation,
      builder: (context, child) {
        final isUrgent = widget.remainingSeconds <= 10;
        final pulseValue = _safeAnimationValue(widget.pulseAnimation);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUrgent
                  ? [Colors.red.shade700, Colors.red.shade900]
                  : [const Color(0xFF6C63FF), const Color(0xFF4834DF)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? Colors.red : const Color(0xFF6C63FF))
                    .withOpacity(0.4 + pulseValue * 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                '${widget.remainingSeconds}s',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Animasyon değerini güvenli şekilde al (0-1 arası clamp)
  double _safeAnimationValue(Animation<double> animation) {
    try {
      return animation.value.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Fallback value
    }
  }
  
  /// Skor widget'ı
  Widget _buildScoreWidget() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ana skor container
        AnimatedScale(
          scale: _scaleValue,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(_scaleValue > 1.0 ? 0.4 : 0.2),
                  Colors.orange.withOpacity(_scaleValue > 1.0 ? 0.3 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
              boxShadow: _scaleValue > 1.0
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                _buildAnimatedScoreText(),
              ],
            ),
          ),
        ),
        
        // Floating +10 text
        if (_showFloatingScore && _floatingController != null)
          _buildFloatingScoreIndicator(),
      ],
    );
  }
  
  /// Animasyonlu skor text
  Widget _buildAnimatedScoreText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        '${widget.score}',
        key: ValueKey(widget.score),
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Floating puan göstergesi
  Widget _buildFloatingScoreIndicator() {
    return Positioned(
      top: -15,
      right: 0,
      left: 0,
      child: AnimatedBuilder(
        animation: _floatingController!,
        builder: (context, child) {
          final value = _safeAnimationValue(_floatingController!);
          
          return Transform.translate(
            offset: Offset(0, -40 * value),
            child: Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '+$_addedPoints',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
