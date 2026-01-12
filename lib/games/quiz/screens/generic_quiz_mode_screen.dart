import 'package:flutter/material.dart';
import '../../../widgets/matchmaking_screen.dart';
import '../../../enums/quiz_difficulty.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../models/quiz_config.dart';
import 'generic_quiz_game_screen.dart';

/// Tüm quiz kategorileri için ortak mod seçim ekranı
/// Solo veya Couple vs Couple modu seçimi
class GenericQuizModeScreen extends StatefulWidget {
  final QuizConfig config;

  const GenericQuizModeScreen({
    super.key,
    required this.config,
  });

  @override
  State<GenericQuizModeScreen> createState() => _GenericQuizModeScreenState();
}

class _GenericQuizModeScreenState extends State<GenericQuizModeScreen> {
  bool _showModeSelection = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 32),
              Expanded(
                child: _showModeSelection
                    ? _buildModeSelection()
                    : _buildDifficultySelection(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (!_showModeSelection) {
                setState(() => _showModeSelection = true);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(widget.config.emoji, style: const TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 16),
        Text(
          widget.config.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.config.subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _showModeSelection ? AppStrings.selectGameMode : AppStrings.selectDifficulty,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Solo Mode - Zorluk seçimi config'e göre belirlenir
          _buildModeCard(
            emoji: '📖',
            title: AppStrings.soloPractice,
            subtitle: AppStrings.soloPracticeSubtitle,
            color: Colors.teal,
            onTap: () => _handleSoloMode(),
          ),
          
          const SizedBox(height: 20),
          
          // Couple vs Couple Mode - Rastgele zorluk
          _buildModeCard(
            emoji: '⚔️',
            title: AppStrings.coupleVsCouple,
            subtitle: AppStrings.coupleVsCoupleSubtitle,
            color: AppTheme.primaryColor,
            isPremium: true,
            onTap: () => _startCoupleVsCouple(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.25),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🏆 ${AppStrings.scoreBadge}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDifficultyCard(QuizDifficulty.easy, '🟢', Colors.green),
          const SizedBox(height: 14),
          _buildDifficultyCard(QuizDifficulty.medium, '🟡', Colors.amber),
          const SizedBox(height: 14),
          _buildDifficultyCard(QuizDifficulty.hard, '🔴', Colors.red),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(QuizDifficulty difficulty, String emoji, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startSoloGame(difficulty),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      difficulty.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// Solo mod handler - config'e göre zorluk seçimi veya karışık mod
  void _handleSoloMode() {
    if (widget.config.hasDifficultySelection) {
      // Zorluk seçimi göster
      setState(() => _showModeSelection = false);
    } else {
      // Karışık zorluk modunda direkt oyunu başlat
      _startMixedDifficultyGame();
    }
  }

  /// Karışık zorluk modunda solo oyun başlat
  void _startMixedDifficultyGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenericQuizGameScreen(
          config: widget.config,
          difficulty: QuizDifficulty.medium, // Default difficulty for mixed mode
          isMultiplayer: false,
          useMixedDifficulty: true, // Karışık zorluk flag'i
        ),
      ),
    );
  }

  void _startSoloGame(QuizDifficulty difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenericQuizGameScreen(
          config: widget.config,
          difficulty: difficulty,
          isMultiplayer: false,
        ),
      ),
    );
  }

  void _startCoupleVsCouple() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchmakingScreen(
          gameType: widget.config.gameType,
          gameMode: 'any',
          onMatched: (roomCode) {
            // Eşleşme oldu - rastgele zorluk belirle
            final randomDifficulty = _getRandomDifficulty();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GenericQuizGameScreen(
                  config: widget.config,
                  difficulty: randomDifficulty,
                  roomCode: roomCode,
                  isMultiplayer: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  QuizDifficulty _getRandomDifficulty() {
    final difficulties = QuizDifficulty.values;
    return difficulties[DateTime.now().millisecondsSinceEpoch % difficulties.length];
  }
}
