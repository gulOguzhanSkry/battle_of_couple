import 'package:flutter/material.dart';
import '../../../models/quiz_category.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_theme.dart';

/// A card widget for quiz category selection
/// 
/// Displays category icon, title, description via an animated card.
/// Has press animation and handles navigation to quiz mode screen.
class QuizCategoryCard extends StatefulWidget {
  final QuizCategory category;
  final Function(QuizCategory) onCategorySelected;

  const QuizCategoryCard({
    super.key,
    required this.category,
    required this.onCategorySelected,
  });

  @override
  State<QuizCategoryCard> createState() => _QuizCategoryCardState();
}

class _QuizCategoryCardState extends State<QuizCategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Longer duration
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () => _handleTap(context),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildBackgroundDecoration(),
              _buildContent(),
              if (!category.isActive) _buildInactiveOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    // Only animate if category is active
    if (!widget.category.isActive) {
      return Positioned(
        top: -20,
        right: -20,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.category.color.withValues(alpha: 0.2),
                widget.category.color.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Positioned(
      top: -20,
      right: -20,
      child: Stack(
        children: [
          // Base Color Layer
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.category.color.withValues(alpha: 0.8), // Increased from 0.2
                  widget.category.color.withValues(alpha: 0.2), // Increased from 0.05
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
          // Shimmer Overlay Layer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-2.0 - _shimmerController.value * 3.5, -1.0),
                    end: Alignment(-2.0 + _shimmerController.value * 3.5, 1.0),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.2), // Faint lead
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.8), // Strong main beam
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.4), // Secondary beam
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.3, 0.4, 0.5, 0.6, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final category = widget.category;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopSection(category),
          _buildBottomSection(category),
        ],
      ),
    );
  }

  Widget _buildTopSection(QuizCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(category),
        const SizedBox(height: 8),
        Text(
          category.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: category.isActive
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          category.description,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIconBadge(QuizCategory category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: category.isActive
              ? category.gradientColors
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: category.isActive
            ? [
                BoxShadow(
                  color: category.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        category.icon,
        size: 22,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomSection(QuizCategory category) {
    return Row(
      children: [
        category.isActive ? _buildPlayButton(category) : _buildComingSoonBadge(),
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: category.isActive ? category.color : AppTheme.textLightColor,
        ),
      ],
    );
  }

  Widget _buildPlayButton(QuizCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: category.gradientColors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.playNow,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.play_arrow_rounded,
            size: 12,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.softPinkBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppStrings.comingSoonBadge,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppTheme.softPinkText,
        ),
      ),
    );
  }

  Widget _buildInactiveOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final category = widget.category;

    if (!category.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('${category.title} ${AppStrings.comingSoonSuffix}'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onCategorySelected(category);
  }
}
