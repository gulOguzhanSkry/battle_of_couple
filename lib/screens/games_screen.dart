import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../widgets/points_display_widget.dart';
import 'quiz_hub_screen.dart';
import 'games/widgets/games_widgets.dart';

/// Games screen displaying all available games and coming soon features
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  AppStrings.gamesTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Team Points Display
                      const PointsDisplayWidget(),
                      const SizedBox(height: 20),
                      
                      // Active Games
                      _buildActiveGames(context),
                      
                      const SizedBox(height: 24),
                      
                      // Coming Soon Section
                      _buildComingSoonSection(context),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGames(BuildContext context) {
    return Column(
      children: [
        // Quiz Hub - Main active game
        ActiveGameCard(
          icon: Icons.school,
          title: AppStrings.quizHubTitle,
          description: AppStrings.gameQuizHubDesc,
          gradientColors: const [
            AppTheme.quizHubPrimary,
            AppTheme.quizHubSecondary,
          ],
          onTap: () => _navigateTo(context, const QuizHubScreen()),
        ),
      ],
    );
  }

  Widget _buildComingSoonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppStrings.sectionComingSoon,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Coming Soon Cards
        ComingSoonCard(
          icon: Icons.people_rounded,
          title: AppStrings.gameCvC,
          description: AppStrings.gameCvCDesc,
          accentColor: AppTheme.coupleVsColor,
        ),
        const SizedBox(height: 16),
        
        ComingSoonCard(
          icon: Icons.card_giftcard_rounded,
          title: AppStrings.gameRaffles,
          description: AppStrings.gameRafflesDesc,
          accentColor: AppTheme.rafflesColor,
        ),
        const SizedBox(height: 16),
        
        ComingSoonCard(
          icon: Icons.celebration_rounded,
          title: AppStrings.gameEvents,
          description: AppStrings.gameEventsDesc,
          accentColor: AppTheme.eventsColor,
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
