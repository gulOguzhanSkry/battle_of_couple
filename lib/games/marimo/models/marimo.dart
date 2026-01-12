import 'package:cloud_firestore/cloud_firestore.dart';

/// Marimo büyüme aşaması
enum MarimoStage {
  seed(1, 'Tohum', 'marimo_stage_1.png'),
  sprout(2, 'Filiz', 'marimo_stage_2.png'),
  young(3, 'Genç', 'marimo_stage_3.png'),
  mature(4, 'Olgun', 'marimo_stage_4.png'),
  adult(5, 'Yetişkin', 'marimo_stage_5.png'),
  magnificent(6, 'Muhteşem', 'marimo_stage_6.png');

  final int level;
  final String displayName;
  final String assetName;
  
  const MarimoStage(this.level, this.displayName, this.assetName);

  /// Bu aşamaya geçmek için gereken toplam XP (Kümülatif değil, o seviye için gereken)
  int get requiredXp => level * 100;
  
  String get assetPath => 'assets/games/marimo/$assetName';
  
  /// Bir sonraki aşama
  MarimoStage? get next {
    if (level >= 6) return null;
    return MarimoStage.values.firstWhere((s) => s.level == level + 1);
  }
  
  /// Bir önceki aşama
  MarimoStage? get previous {
    if (level <= 1) return null;
    return MarimoStage.values.firstWhere((s) => s.level == level - 1);
  }
}

/// Marimo aksiyon türü
enum MarimoActionType {
  changeWater('💧', 'Suyu Değiştir', 'Su değiştirildi'),
  addFood('🌱', 'Besin Ekle', 'Besin eklendi');

  final String emoji;
  final String displayName;
  final String pastTense;
  
  const MarimoActionType(this.emoji, this.displayName, this.pastTense);
}

/// Yapılan bir aksiyon kaydı
class MarimoAction {
  final String id;
  final MarimoActionType type;
  final String userId;
  final String userName;
  final DateTime timestamp;

  const MarimoAction({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory MarimoAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarimoAction(
      id: doc.id,
      type: MarimoActionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => MarimoActionType.changeWater,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Ana Marimo modeli
class Marimo {
  final String id;
  final String coupleId;
  final String name;
  final MarimoStage stage;
  final int health; // 0-100
  final int experience; // Büyüme için XP
  final int waterQuality; // 0-100, zamanla düşer
  final int foodLevel; // 0-100, zamanla düşer
  final DateTime lastWaterChange;
  final DateTime lastFed;
  final String? lastWaterChangedBy;
  final String? lastFedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDead;

  const Marimo({
    required this.id,
    required this.coupleId,
    required this.name,
    required this.stage,
    required this.health,
    required this.experience,
    required this.waterQuality,
    required this.foodLevel,
    required this.lastWaterChange,
    required this.lastFed,
    this.lastWaterChangedBy,
    this.lastFedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isDead = false,
  });

  /// Yeni Marimo oluştur
  factory Marimo.create({
    required String coupleId,
    String name = 'Marimosu',
  }) {
    final now = DateTime.now();
    return Marimo(
      id: '',
      coupleId: coupleId,
      name: name,
      stage: MarimoStage.seed,
      health: 100,
      experience: 0,
      waterQuality: 100,
      foodLevel: 100,
      lastWaterChange: now,
      lastFed: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Marimo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Marimo(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      name: data['name'] ?? 'Marimosu',
      stage: MarimoStage.values.firstWhere(
        (s) => s.name == data['stage'],
        orElse: () => MarimoStage.seed,
      ),
      health: data['health'] ?? 100,
      experience: data['experience'] ?? 0,
      waterQuality: data['waterQuality'] ?? 100,
      foodLevel: data['foodLevel'] ?? 100,
      lastWaterChange: (data['lastWaterChange'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastFed: (data['lastFed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastWaterChangedBy: data['lastWaterChangedBy'],
      lastFedBy: data['lastFedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDead: data['isDead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'name': name,
      'stage': stage.name,
      'health': health,
      'experience': experience,
      'waterQuality': waterQuality,
      'foodLevel': foodLevel,
      'lastWaterChange': Timestamp.fromDate(lastWaterChange),
      'lastFed': Timestamp.fromDate(lastFed),
      'lastWaterChangedBy': lastWaterChangedBy,
      'lastFedBy': lastFedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDead': isDead,
    };
  }

  /// Marimo'nun mevcut durumu
  String get statusText {
    if (isDead) return '💀 Öldü';
    if (health < 20) return '😰 Çok Kötü';
    if (health < 40) return '😟 Kötü';
    if (health < 60) return '😐 İdare Eder';
    if (health < 80) return '😊 İyi';
    return '😍 Muhteşem';
  }

  /// Su kalitesi durumu
  String get waterStatusText {
    if (waterQuality < 20) return '🟤 Çok Kirli';
    if (waterQuality < 40) return '🟡 Kirli';
    if (waterQuality < 60) return '🟢 Normal';
    if (waterQuality < 80) return '🔵 Temiz';
    return '💎 Kristal';
  }

  /// Besin durumu
  String get foodStatusText {
    if (foodLevel < 20) return '😫 Çok Aç';
    if (foodLevel < 40) return '😕 Aç';
    if (foodLevel < 60) return '😐 Normal';
    if (foodLevel < 80) return '😊 Tok';
    return '🤗 Çok Tok';
  }

  /// Hasta mı? (düşük sağlık)
  bool get isSick => health < 40;

  /// Büyüme için gereken XP
  int get experienceForNextStage {
    return stage.level * 100; // Her aşama için daha fazla XP
  }

  /// Büyüme yüzdesi
  double get growthProgress {
    if (stage.next == null) return 1.0;
    return experience / experienceForNextStage;
  }

  /// Kopyala ve güncelle
  Marimo copyWith({
    String? name,
    MarimoStage? stage,
    int? health,
    int? experience,
    int? waterQuality,
    int? foodLevel,
    DateTime? lastWaterChange,
    DateTime? lastFed,
    String? lastWaterChangedBy,
    String? lastFedBy,
    DateTime? updatedAt,
    bool? isDead,
  }) {
    return Marimo(
      id: id,
      coupleId: coupleId,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      health: health ?? this.health,
      experience: experience ?? this.experience,
      waterQuality: waterQuality ?? this.waterQuality,
      foodLevel: foodLevel ?? this.foodLevel,
      lastWaterChange: lastWaterChange ?? this.lastWaterChange,
      lastFed: lastFed ?? this.lastFed,
      lastWaterChangedBy: lastWaterChangedBy ?? this.lastWaterChangedBy,
      lastFedBy: lastFedBy ?? this.lastFedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDead: isDead ?? this.isDead,
    );
  }
}
