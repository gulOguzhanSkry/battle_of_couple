import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exam_report_model.dart';
import '../models/ai_report_service_factory.dart';
import '../services/pdf_report_generator.dart';
import '../widgets/quiz_result_widgets.dart';

/// AI Sınav Raporu Widget'ı
/// Kullanıcı isteğinde AI'ye analiz raporu oluşturur
class QuizAIReportWidget extends StatefulWidget {
  final List<AnswerRecord> answers;
  final String categoryId;
  final String categoryName;
  final String userName;

  const QuizAIReportWidget({
    super.key,
    required this.answers,
    required this.categoryId,
    required this.categoryName,
    required this.userName,
  });

  @override
  State<QuizAIReportWidget> createState() => _QuizAIReportWidgetState();
}

class _QuizAIReportWidgetState extends State<QuizAIReportWidget> {
  ExamReport? _report;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  String? _error;
  bool _hasRequested = false; // Kullanıcı istedi mi?

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasRequested = true;
    });

    try {
      final service = AIReportServiceFactory.getAvailableService();
      
      if (service == null) {
        throw Exception('Yapay zeka servisi bulunamadı. API anahtarını kontrol edin.');
      }

      // Yanlış cevapları filtrele ve dönüştür
      final wrongAnswers = widget.answers
          .where((a) => !a.isCorrect)
          .map((a) => WrongAnswerData(
                questionText: a.question.questionText,
                correctAnswer: a.question.options[a.question.correctOptionIndex],
                userAnswer: a.question.options[a.selectedIndex],
                topic: a.question.topic,
                subCategory: a.question.subCategory,
              ))
          .toList();

      final correctCount = widget.answers.where((a) => a.isCorrect).length;

      final report = await service.generateExamReport(
        wrongAnswers: wrongAnswers,
        categoryId: widget.categoryId,
        totalQuestions: widget.answers.length,
        correctCount: correctCount,
      );

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_report == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final filePath = await PdfReportGenerator.generatePdf(
        report: _report!,
        categoryName: widget.categoryName,
        userName: widget.userName,
      );

      // PDF'i paylaş
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'AI Sınav Raporu - ${widget.categoryName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Henüz istek yapılmadıysa sadece buton göster
    if (!_hasRequested) {
      return _buildRequestButton();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.2),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_isLoading) _buildLoadingState(),
          if (_error != null) _buildErrorState(),
          if (_report != null) _buildReportContent(),
        ],
      ),
    );
  }

  /// Rapor oluşturma butonu - ilk ekran
  Widget _buildRequestButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateReport,
          icon: const Text('🤖', style: TextStyle(fontSize: 20)),
          label: const Text('AI Sınav Raporu Oluştur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Text('🤖', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Sınav Raporu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Yapay zeka destekli performans analizi',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_report != null)
          _isGeneratingPdf
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : IconButton(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.download, color: Colors.white),
                  tooltip: 'PDF İndir',
                ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Colors.indigo,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rapor oluşturuluyor...',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Yapay zeka cevaplarınızı analiz ediyor',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Rapor oluşturulamadı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Bilinmeyen hata',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performans göstergesi
        _buildPerformanceBadge(),
        const SizedBox(height: 16),
        
        // Genel değerlendirme
        _buildSection(
          icon: '📊',
          title: 'Genel Değerlendirme',
          child: Text(
            _report!.overallAnalysis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        
        // Zayıf konular
        if (_report!.weakTopics.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            icon: '📚',
            title: 'Geliştirilmesi Gereken Konular',
            child: Column(
              children: _report!.weakTopics
                  .map((topic) => _buildWeakTopicCard(topic))
                  .toList(),
            ),
          ),
        ],
        
        // Öneriler
        const SizedBox(height: 16),
        _buildSection(
          icon: '💡',
          title: 'Öneriler',
          child: Column(
            children: _report!.recommendations
                .asMap()
                .entries
                .map((e) => _buildRecommendationItem(e.key + 1, e.value))
                .toList(),
          ),
        ),
        
        // PDF İndir butonu
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _downloadPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGeneratingPdf ? 'PDF Oluşturuluyor...' : 'PDF Olarak İndir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBadge() {
    final colors = {
      'Mükemmel': Colors.green,
      'İyi': Colors.blue,
      'Orta': Colors.orange,
      'Geliştirilmeli': Colors.red,
    };
    final color = colors[_report!.performanceLevel] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _report!.performanceLevel == 'Mükemmel'
                ? Icons.emoji_events
                : _report!.performanceLevel == 'Geliştirilmeli'
                    ? Icons.trending_up
                    : Icons.star,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Performans: ${_report!.performanceLevel}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(%${_report!.successRate.toStringAsFixed(0)})',
            style: TextStyle(color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildWeakTopicCard(WeakTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topic.topicName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${topic.wrongCount} hata',
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            topic.explanation,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
