/// Yapay Zeka Sınav Raporu veri modelleri

/// Yanlış cevap verisi - AI'ye gönderilecek format
class WrongAnswerData {
  final String questionText;
  final String correctAnswer;
  final String userAnswer;
  final String? topic;
  final String? subCategory;

  const WrongAnswerData({
    required this.questionText,
    required this.correctAnswer,
    required this.userAnswer,
    this.topic,
    this.subCategory,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': questionText,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      if (topic != null) 'topic': topic,
      if (subCategory != null) 'subCategory': subCategory,
    };
  }
}

/// Zayıf konu analizi
class WeakTopic {
  final String topicName;
  final String explanation;
  final int wrongCount;
  final List<String> relatedQuestions;

  const WeakTopic({
    required this.topicName,
    required this.explanation,
    required this.wrongCount,
    this.relatedQuestions = const [],
  });

  factory WeakTopic.fromJson(Map<String, dynamic> json) {
    return WeakTopic(
      topicName: json['topicName'] as String? ?? 'Bilinmeyen Konu',
      explanation: json['explanation'] as String? ?? '',
      wrongCount: json['wrongCount'] as int? ?? 1,
      relatedQuestions: json['relatedQuestions'] != null
          ? List<String>.from(json['relatedQuestions'])
          : [],
    );
  }
}

/// AI tarafından üretilen sınav raporu
class ExamReport {
  final List<WeakTopic> weakTopics;
  final String overallAnalysis;
  final List<String> recommendations;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final DateTime generatedAt;

  const ExamReport({
    required this.weakTopics,
    required this.overallAnalysis,
    required this.recommendations,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.generatedAt,
  });

  /// Başarı yüzdesi
  double get successRate => totalQuestions > 0 
      ? (correctCount / totalQuestions) * 100 
      : 0;

  /// Performance seviyesi
  String get performanceLevel {
    final rate = successRate;
    if (rate >= 80) return 'Mükemmel';
    if (rate >= 60) return 'İyi';
    if (rate >= 40) return 'Orta';
    return 'Geliştirilmeli';
  }

  factory ExamReport.fromJson(
    Map<String, dynamic> json, {
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
  }) {
    return ExamReport(
      weakTopics: (json['weakTopics'] as List<dynamic>?)
              ?.map((e) => WeakTopic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallAnalysis: json['overallAnalysis'] as String? ?? '',
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : [],
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      generatedAt: DateTime.now(),
    );
  }

  /// Boş rapor oluştur (tüm sorular doğru)
  factory ExamReport.perfect({
    required int totalQuestions,
  }) {
    return ExamReport(
      weakTopics: [],
      overallAnalysis: 'Tebrikler! Tüm soruları doğru cevapladınız. Harika bir performans sergidiniz.',
      recommendations: [
        'Bu başarıyı korumaya devam edin.',
        'Daha zor seviye sorularla kendinizi test edin.',
        'Öğrendiklerinizi başkalarıyla paylaşın.',
      ],
      totalQuestions: totalQuestions,
      correctCount: totalQuestions,
      wrongCount: 0,
      generatedAt: DateTime.now(),
    );
  }
}
