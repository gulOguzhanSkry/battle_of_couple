/// AI servis hatalarını temsil eden özel exception sınıfı.
/// 
/// Tüm AI servisleri (OpenAI, Gemini, vb.) bu exception'ı kullanarak
/// anlamlı ve tutarlı hata mesajları döndürür.
class AIServiceException implements Exception {
  /// Hatayı üreten servis sağlayıcı adı (örn: "OpenAI", "Gemini")
  final String provider;
  
  /// Kullanıcı dostu hata mesajı
  final String message;
  
  /// Opsiyonel teknik detaylar (API yanıtı, stack trace, vb.)
  final String? details;

  AIServiceException({
    required this.provider,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    final buffer = StringBuffer('[$provider] $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }
}
