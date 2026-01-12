import 'package:flutter/material.dart';
import '../models/quiz_category.dart';
import '../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import '../core/utils/responsive_utils.dart';
import 'quiz_hub/widgets/quiz_hub_widgets.dart';

import '../games/quiz/screens/generic_quiz_mode_screen.dart';

/// Quiz Hub screen - displays all available quiz categories
class QuizHubScreen extends StatefulWidget {
  const QuizHubScreen({super.key});

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  Color? _selectedColor;

  void _handleCategorySelection(QuizCategory category) async {
    // Change theme colors to category color
    setState(() {
      _selectedColor = category.color;
    });

    // Wait for 0.8 seconds
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;

    // Navigate
    if (category.config != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenericQuizModeScreen(config: category.config!),
        ),
      );
      
      // Reset color when coming back
      if (mounted) {
        setState(() {
          _selectedColor = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = QuizCategory.availableCategories;
    final isMobile = ResponsiveUtils.isMobile(context);

    // ... (rest of build method same)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.quizHubBgStart,
              AppTheme.quizHubBgMiddle,
              AppTheme.quizHubBgEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              
              // ... (rest of slivers)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.0 : 2.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => QuizCategoryCard(
                      category: categories[index],
                      onCategorySelected: _handleCategorySelection,
                    ),
                    childCount: categories.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildBackButton(context),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          _buildTitleSection(context),
        ],
      ),
    );
  }

  // ... (_buildBackButton same)
  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.primaryColor,
          size: 18,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final isSelected = _selectedColor != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Icon decoration
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        _selectedColor!,
                        _selectedColor!.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? _selectedColor! : AppTheme.primaryColor)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.videogame_asset_rounded,
              size: 36,
              color: Colors.white, // Always white for contrast
            ),
          ),
          const SizedBox(height: 16),
          // Title with color animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSelected
                ? Text(
                    AppStrings.quizHubTitle,
                    key: const ValueKey('selectedTitle'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _selectedColor, // Category color
                          letterSpacing: 0.5,
                        ),
                  )
                : ShaderMask(
                    key: const ValueKey('defaultTitle'),
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      AppStrings.quizHubTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            AppStrings.quizHubSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
