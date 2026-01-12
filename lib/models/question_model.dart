import 'package:cloud_firestore/cloud_firestore.dart';

/// Soru modeli - Hiyerarşik kategori yapısı:
/// 
/// categoryId (zorunlu) → Ana kategori (KPSS, TUS, AYT...)
///   └── subCategory (opsiyonel) → Alt kategori (Tarih, Biyoloji, Matematik...)
///       └── topic (opsiyonel) → Konu başlığı (Osmanlı Kuruluş Dönemi, Hücre Bölünmesi...)
class QuestionModel {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String categoryId; // Ana kategori: 'kpss', 'tus', 'general_culture', etc. (ZORUNLU)
  final String difficulty; // 'easy', 'medium', 'hard'
  final DateTime createdAt;
  final String createdBy; // Admin ID
  
  // Hiyerarşik kategori alanları (opsiyonel)
  final String? subCategory;  // Alt kategori: Tarih, Biyoloji, vb.
  final String? topic;        // Konu başlığı: Osmanlı Kuruluş Dönemi, vb.
  
  // İçerik alanları (opsiyonel)
  final String? explanation;  // Doğru cevabın açıklaması
  
  // Medya alanları (opsiyonel)
  final String? imageUrl;     // Görsel URL'i
  final String? audioUrl;     // Ses dosyası URL'i

  // Firestore Field Keys
  static const String keyId = 'id';
  static const String keyQuestionText = 'questionText';
  static const String keyOptions = 'options';
  static const String keyCorrectOptionIndex = 'correctOptionIndex';
  static const String keyCategoryId = 'categoryId';
  static const String keyDifficulty = 'difficulty';
  static const String keyCreatedAt = 'createdAt';
  static const String keyCreatedBy = 'createdBy';
  static const String keySubCategory = 'subCategory';
  static const String keyTopic = 'topic';
  static const String keyExplanation = 'explanation';
  static const String keyImageUrl = 'imageUrl';
  static const String keyAudioUrl = 'audioUrl';

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.categoryId,
    this.difficulty = 'medium',
    required this.createdAt,
    required this.createdBy,
    // Opsiyonel kategori alanları
    this.subCategory,
    this.topic,
    // Opsiyonel içerik alanları
    this.explanation,
    // Opsiyonel medya alanları
    this.imageUrl,
    this.audioUrl,
  });

  // Helper getter'lar
  bool get hasSubCategory => subCategory != null && subCategory!.isNotEmpty;
  bool get hasTopic => topic != null && topic!.isNotEmpty;
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasAnyMedia => hasImage || hasAudio;
  
  /// Kategori hiyerarşisini birleştirerek döndürür
  /// Örn: "KPSS > Tarih > Osmanlı Kuruluş Dönemi"
  String get fullCategoryPath {
    final parts = [categoryId];
    if (hasSubCategory) parts.add(subCategory!);
    if (hasTopic) parts.add(topic!);
    return parts.join(' > ');
  }

  Map<String, dynamic> toFirestore() {
    return {
      keyQuestionText: questionText,
      keyOptions: options,
      keyCorrectOptionIndex: correctOptionIndex,
      keyCategoryId: categoryId,
      keyDifficulty: difficulty,
      keyCreatedAt: Timestamp.fromDate(createdAt),
      keyCreatedBy: createdBy,
      // Opsiyonel alanlar - sadece değer varsa kaydet
      if (subCategory != null) keySubCategory: subCategory,
      if (topic != null) keyTopic: topic,
      if (explanation != null) keyExplanation: explanation,
      if (imageUrl != null) keyImageUrl: imageUrl,
      if (audioUrl != null) keyAudioUrl: audioUrl,
    };
  }

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      questionText: data[keyQuestionText] ?? '',
      options: List<String>.from(data[keyOptions] ?? []),
      correctOptionIndex: data[keyCorrectOptionIndex] ?? 0,
      categoryId: data[keyCategoryId] ?? 'general',
      difficulty: data[keyDifficulty] ?? 'medium',
      createdAt: (data[keyCreatedAt] as Timestamp).toDate(),
      createdBy: data[keyCreatedBy] ?? '',
      // Opsiyonel alanlar
      subCategory: data[keySubCategory] as String?,
      topic: data[keyTopic] as String?,
      explanation: data[keyExplanation] as String?,
      imageUrl: data[keyImageUrl] as String?,
      audioUrl: data[keyAudioUrl] as String?,
    );
  }
  
  /// CopyWith metodu - mevcut model'i kısmen güncellemek için
  QuestionModel copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
    String? categoryId,
    String? difficulty,
    DateTime? createdAt,
    String? createdBy,
    String? subCategory,
    String? topic,
    String? explanation,
    String? imageUrl,
    String? audioUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      subCategory: subCategory ?? this.subCategory,
      topic: topic ?? this.topic,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}
