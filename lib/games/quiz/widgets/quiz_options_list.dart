import 'package:flutter/material.dart';
import '../../../models/question_model.dart';

/// Quiz şık listesi
class QuizOptionsList extends StatelessWidget {
  final QuestionModel question;
  final int selectedOption;
  final bool showResult;
  final Function(int) onOptionSelected;

  const QuizOptionsList({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.showResult,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(question.options.length, (index) {
          final isSelected = selectedOption == index;
          final isCorrect = index == question.correctOptionIndex;
          
          Color bgColor = Colors.white.withOpacity(0.08);
          Color borderColor = Colors.white.withOpacity(0.2);
          
          if (showResult) {
            if (isCorrect) {
              bgColor = Colors.green.withOpacity(0.3);
              borderColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              bgColor = Colors.red.withOpacity(0.3);
              borderColor = Colors.red;
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: showResult ? null : () => onOptionSelected(index),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      if (showResult && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      if (showResult && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
