import 'exam_report_model.dart';

/// AI Sınav Raporu üretme servisi için abstract interface.
/// OpenAI ve Gemini servisleri bu interface'i implement eder.
abstract class AIExamReportService {
  /// Servis sağlayıcı adı
  String get providerName;
  
  /// API anahtarının mevcut olup olmadığını kontrol eder
  bool get isConfigured;
  
  /// Yanlış cevaplara göre sınav raporu üretir
  /// 
  /// [wrongAnswers] - Kullanıcının yanlış cevapladığı sorular
  /// [categoryId] - Quiz kategorisi (PDR, KPSS, etc.)
  /// [totalQuestions] - Toplam soru sayısı
  /// [correctCount] - Doğru cevap sayısı
  Future<ExamReport> generateExamReport({
    required List<WrongAnswerData> wrongAnswers,
    required String categoryId,
    required int totalQuestions,
    required int correctCount,
  });
}
