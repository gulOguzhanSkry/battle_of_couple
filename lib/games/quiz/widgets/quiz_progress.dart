import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

/// Quiz ilerleme göstergesi
class QuizProgress extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;

  const QuizProgress({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.questionProgress} ${currentIndex + 1} / $totalQuestions',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              Row(
                children: [
                  _buildMiniStat('✓', correctCount, Colors.greenAccent),
                  const SizedBox(width: 12),
                  _buildMiniStat('✗', wrongCount, Colors.redAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalQuestions == 0 ? 0.0 : (currentIndex + 1) / totalQuestions,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
