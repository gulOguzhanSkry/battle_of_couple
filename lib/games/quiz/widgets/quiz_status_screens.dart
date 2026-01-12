import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

/// Rakip bekleme ekranı
class QuizWaitingScreen extends StatelessWidget {
  final int? currentScore;

  const QuizWaitingScreen({
    super.key,
    this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            AppStrings.waitingOpponent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (currentScore != null) ...[
            Text(
              '${AppStrings.scoreLabel} $currentScore',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
            const SizedBox(height: 20),
          ] else
            Text(
              AppStrings.waitingOpponentSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.pink),
        ],
      ),
    );
  }
}

/// Yükleme ekranı
class QuizLoadingScreen extends StatelessWidget {
  const QuizLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.questionsPreparing,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
          ),
        ],
      ),
    );
  }
}

/// Soru bulunamadı ekranı
class QuizNoQuestionsScreen extends StatelessWidget {
  final String categoryTitle;
  final VoidCallback onBack;

  const QuizNoQuestionsScreen({
    super.key,
    required this.categoryTitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😔', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Henüz $categoryTitle sorusu yok',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin panelinden soru ekleyin',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }
}
