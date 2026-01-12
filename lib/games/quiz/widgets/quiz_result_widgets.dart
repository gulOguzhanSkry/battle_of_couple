import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/question_model.dart';

/// Cevap kaydı modeli
class AnswerRecord {
  final QuestionModel question;
  final int selectedIndex;
  final bool isCorrect;

  AnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.isCorrect,
  });
}

/// Solo sonuç özet kartı
class QuizSummaryCard extends StatelessWidget {
  final int score;
  final int correctCount;
  final int wrongCount;
  final int percentage;

  const QuizSummaryCard({
    super.key,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(AppStrings.statsScore, '$score', Colors.amber),
          _buildStatItem(AppStrings.statsCorrect, '$correctCount', Colors.green),
          _buildStatItem(AppStrings.statsWrong, '$wrongCount', Colors.red),
          _buildStatItem(AppStrings.statsRate, '%$percentage', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }
}

/// Cevap geçmişi listesi
class QuizAnswerList extends StatelessWidget {
  final List<AnswerRecord> answers;

  const QuizAnswerList({
    super.key,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.answerHistory,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(answers.length, (index) {
          final answer = answers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: answer.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: answer.isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: answer.isCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      answer.isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answer.question.questionText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
