import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // pixels per second
  final double pauseDuration; // seconds

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 30.0,
    this.pauseDuration = 2.0,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted) return;
    
    // Calculate scroll duration based on content width
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    if (maxScrollExtent > 0) {
      final duration = Duration(milliseconds: (maxScrollExtent / widget.velocity * 1000).round());
      
      _animation = Tween<double>(begin: 0.0, end: maxScrollExtent).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear),
      );

      _animationController.duration = duration;

      _animate();
    }
  }

  void _animate() async {
    if (!mounted) return;
    
    try {
      // Scroll to end
      await _animationController.forward();
      if (!mounted) return;
      
      // Pause at end
      await Future.delayed(Duration(milliseconds: (widget.pauseDuration * 1000).round()));
      if (!mounted) return;
      
      // Jump back to start
      _animationController.reset();
      
      // Pause at start
      await Future.delayed(Duration(milliseconds: (widget.pauseDuration * 1000).round()));
      
      // Repeat
      _animate();
    } catch (e) {
      // Animation interrupted or disposed
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_animationController.value * _scrollController.position.maxScrollExtent);
        }
        return ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Text(widget.text, style: widget.style),
          ],
        );
      },
    );
  }
}
