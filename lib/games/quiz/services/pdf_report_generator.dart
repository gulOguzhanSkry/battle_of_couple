import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/exam_report_model.dart';

/// PDF sınav raporu oluşturucu
/// ExamReport modelinden profesyonel bir PDF belgesi üretir
class PdfReportGenerator {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  
  /// Font yükle (Türkçe karakter desteği için)
  static Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    
    try {
      // Google Fonts'tan Roboto yükle (GitHub Raw - Daha stabil)
      final regularFontData = await _downloadFont(
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-Regular.ttf'
      );
      final boldFontData = await _downloadFont(
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-Bold.ttf'
      );
      
      if (regularFontData != null) {
        _regularFont = pw.Font.ttf(ByteData.view(regularFontData.buffer));
      }
      if (boldFontData != null) {
        _boldFont = pw.Font.ttf(ByteData.view(boldFontData.buffer));
      }
    } catch (e) {
      debugPrint('[PdfReportGenerator] Font loading error: $e');
    }
  }
  
  static Future<Uint8List?> _downloadFont(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[PdfReportGenerator] Font download error: $e');
    }
    return null;
  }
  
  /// PDF raporu oluştur ve dosya yolunu döndür
  static Future<String> generatePdf({
    required ExamReport report,
    required String categoryName,
    required String userName,
  }) async {
    try {
      // Önce fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: _regularFont,
            bold: _boldFont,
          ),
          header: (context) => _buildHeader(categoryName, userName),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildScoreSummary(report),
            pw.SizedBox(height: 20),
            _buildPerformanceIndicator(report),
            pw.SizedBox(height: 24),
            _buildOverallAnalysis(report),
            pw.SizedBox(height: 24),
            if (report.weakTopics.isNotEmpty) ...[
              _buildWeakTopicsSection(report),
              pw.SizedBox(height: 24),
            ],
            _buildRecommendationsSection(report),
          ],
        ),
      );

      return await _savePdf(pdf, categoryName);
    } catch (e) {
      debugPrint('[PdfReportGenerator] Error generating PDF: $e');
      rethrow;
    }
  }

  /// Header bölümü
  static pw.Widget _buildHeader(String categoryName, String userName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '🎓 AI Sınav Raporu',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '$categoryName Kategorisi',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                userName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _formatDate(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer bölümü
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Sayfa ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
      ),
    );
  }

  /// Skor özet kutusu
  static pw.Widget _buildScoreSummary(ExamReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox('Toplam', '${report.totalQuestions}', PdfColors.blue700),
          _buildStatBox('Doğru', '${report.correctCount}', PdfColors.green700),
          _buildStatBox('Yanlış', '${report.wrongCount}', PdfColors.red700),
          _buildStatBox('Başarı', '%${report.successRate.toStringAsFixed(0)}', PdfColors.amber700),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Performans göstergesi
  static pw.Widget _buildPerformanceIndicator(ExamReport report) {
    final colors = {
      'Mükemmel': PdfColors.green700,
      'İyi': PdfColors.blue700,
      'Orta': PdfColors.orange700,
      'Geliştirilmeli': PdfColors.red700,
    };
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: colors[report.performanceLevel]!.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: colors[report.performanceLevel]!, width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          'Performans: ${report.performanceLevel}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: colors[report.performanceLevel],
          ),
        ),
      ),
    );
  }

  /// Genel değerlendirme
  static pw.Widget _buildOverallAnalysis(ExamReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📊 Genel Değerlendirme',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.overallAnalysis,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  /// Zayıf konular bölümü
  static pw.Widget _buildWeakTopicsSection(ExamReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '📚 Geliştirilmesi Gereken Konular',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red800,
          ),
        ),
        pw.SizedBox(height: 12),
        ...report.weakTopics.map((topic) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    topic.topicName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red200,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      '${topic.wrongCount} hata',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                topic.explanation,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Öneriler bölümü
  static pw.Widget _buildRecommendationsSection(ExamReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💡 Öneriler',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...report.recommendations.asMap().entries.map((entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green600,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${entry.key + 1}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    entry.value,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// PDF'i kaydet ve dosya yolunu döndür
  static Future<String> _savePdf(pw.Document pdf, String categoryName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sinav_raporu_${categoryName.toLowerCase()}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('[PdfReportGenerator] PDF saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[PdfReportGenerator] Error saving PDF: $e');
      rethrow;
    }
  }

  /// Tarih formatla
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
