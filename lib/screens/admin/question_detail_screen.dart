import 'package:flutter/material.dart';
import '../../models/question_model.dart';


class QuestionDetailScreen extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Soru Detayı'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Sil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  label: question.categoryId,
                  color: _getCategoryColor(question.categoryId),
                ),
                _buildChip(
                  label: _getDifficultyLabel(question.difficulty),
                  color: _getDifficultyColor(question.difficulty),
                ),
                if (question.hasTopic)
                  _buildChip(
                    label: question.topic!,
                    color: Colors.grey.shade700,
                    icon: Icons.tag,
                    isOutline: true,
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Question Text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            
            // Image
            if (question.hasImage) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: Image.network(
                    question.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Resim yüklenemedi', style: TextStyle(color: Colors.grey.shade600))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Options Header
            Text(
              'Seçenekler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            
            // Options List
            ...question.options.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final isCorrect = i == question.correctOptionIndex;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.grey.shade300,
                    width: isCorrect ? 2 : 1,
                  ),
                  boxShadow: [
                    if (!isCorrect)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isCorrect ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        ['A', 'B', 'C', 'D'][i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.white : Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                          color: isCorrect ? Colors.green.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Doğru',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            }),
            
            // Explanation
            if (question.hasExplanation) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Açıklama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.explanation!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    IconData? icon,
    bool isOutline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.grey.shade100 : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutline ? Colors.grey.shade300 : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy': return 'Kolay';
      case 'medium': return 'Orta';
      case 'hard': return 'Zor';
      default: return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getCategoryColor(String categoryId) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[categoryId.hashCode.abs() % colors.length];
  }
}
