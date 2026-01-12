/// AI Service sabitleri ve konfigürasyonları
class AIConstants {
  // OpenAI
  static const String openAIModel = 'gpt-5-mini';
  static const String openAIBaseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Gemini
  static const String geminiModel = 'gemini-1.5-flash';
  
  // Prompt defaults
  static const int defaultQuestionCount = 5;
  static const int optionsCount = 4;
  
  // Timeout
  static const Duration requestTimeout = Duration(seconds: 90);
  
  // System Prompts
  static const String systemPromptJson = 
      'Sen yardımcı bir asistansın. Sadece JSON formatında yanıt ver.';
}
