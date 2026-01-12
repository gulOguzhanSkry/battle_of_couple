import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/room_status.dart';

/// Oyun odası modeli - çift vs çift eşleşmeleri için
class GameRoom {
  final String code;          // Okunabilir oda kodu (örn: KALP-3847)
  final String hostCoupleId;
  final String hostTeamName;
  final String? guestCoupleId;
  final String? guestTeamName;
  final String gameType;      // heart_shooter, quiz, vs.
  final String gameMode;      // couples_vs
  final RoomStatus status;
  final DateTime createdAt;
  final DateTime? matchedAt;
  final String? sessionId;    // Oyun başladığında GameSession ID
  
  // Skor alanları - gerçek zamanlı güncellenir
  final int hostScore;
  final int guestScore;
  final int hostCorrect;
  final int guestCorrect;
  final bool hostFinished;
  final bool guestFinished;
  
  // Senkronize başlama alanları
  final bool hostReady;
  final bool guestReady;
  final int questionCount;
  final int gameDuration; // saniye

  const GameRoom({
    required this.code,
    required this.hostCoupleId,
    required this.hostTeamName,
    this.guestCoupleId,
    this.guestTeamName,
    required this.gameType,
    required this.gameMode,
    required this.status,
    required this.createdAt,
    this.matchedAt,
    this.sessionId,
    this.hostScore = 0,
    this.guestScore = 0,
    this.hostCorrect = 0,
    this.guestCorrect = 0,
    this.hostFinished = false,
    this.guestFinished = false,
    this.hostReady = false,
    this.guestReady = false,
    this.questionCount = 10,
    this.gameDuration = 60,
  });

  /// Okunabilir oda kodu oluştur (KALP-XXXX formatı)
  static String generateCode() {
    final prefixes = ['KALP', 'AŞIK', 'ÇIFT', 'OYUN', 'DÜET'];
    final prefix = prefixes[DateTime.now().millisecond % prefixes.length];
    final number = (1000 + DateTime.now().microsecond % 9000).toString();
    return '$prefix-$number';
  }

  /// Firestore'dan oluştur
  factory GameRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameRoom(
      code: doc.id,
      hostCoupleId: data['hostCoupleId'] ?? '',
      hostTeamName: data['hostTeamName'] ?? '',
      guestCoupleId: data['guestCoupleId'],
      guestTeamName: data['guestTeamName'],
      gameType: data['gameType'] ?? '',
      gameMode: data['gameMode'] ?? '',
      status: RoomStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RoomStatus.waiting,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchedAt: (data['matchedAt'] as Timestamp?)?.toDate(),
      sessionId: data['sessionId'],
      hostScore: data['hostScore'] ?? 0,
      guestScore: data['guestScore'] ?? 0,
      hostCorrect: data['hostCorrect'] ?? 0,
      guestCorrect: data['guestCorrect'] ?? 0,
      hostFinished: data['hostFinished'] ?? false,
      guestFinished: data['guestFinished'] ?? false,
      hostReady: data['hostReady'] ?? false,
      guestReady: data['guestReady'] ?? false,
      questionCount: data['questionCount'] ?? 10,
      gameDuration: data['gameDuration'] ?? 60,
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'hostCoupleId': hostCoupleId,
      'hostTeamName': hostTeamName,
      'guestCoupleId': guestCoupleId,
      'guestTeamName': guestTeamName,
      'gameType': gameType,
      'gameMode': gameMode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'matchedAt': matchedAt != null ? Timestamp.fromDate(matchedAt!) : null,
      'sessionId': sessionId,
      'hostScore': hostScore,
      'guestScore': guestScore,
      'hostCorrect': hostCorrect,
      'guestCorrect': guestCorrect,
      'hostFinished': hostFinished,
      'guestFinished': guestFinished,
      'hostReady': hostReady,
      'guestReady': guestReady,
      'questionCount': questionCount,
      'gameDuration': gameDuration,
    };
  }

  /// Eşleşme tamamlandı mı?
  bool get isMatched => guestCoupleId != null && status == RoomStatus.matched;
  
  /// Her iki takım da bitirdi mi?
  bool get isGameComplete => hostFinished && guestFinished;
  
  /// Her iki takım da hazır mı? (oyun başlayabilir)
  bool get isAllReady => hostReady && guestReady;
  
  /// Kazanan takım (null = berabere veya bitmedi)
  String? get winnerTeamName {
    if (!isGameComplete) return null;
    if (hostScore > guestScore) return hostTeamName;
    if (guestScore > hostScore) return guestTeamName;
    return null; // Berabere
  }

  /// Kopyala ve güncelle
  GameRoom copyWith({
    String? guestCoupleId,
    String? guestTeamName,
    RoomStatus? status,
    DateTime? matchedAt,
    String? sessionId,
    int? hostScore,
    int? guestScore,
    int? hostCorrect,
    int? guestCorrect,
    bool? hostFinished,
    bool? guestFinished,
    bool? hostReady,
    bool? guestReady,
    int? questionCount,
    int? gameDuration,
  }) {
    return GameRoom(
      code: code,
      hostCoupleId: hostCoupleId,
      hostTeamName: hostTeamName,
      guestCoupleId: guestCoupleId ?? this.guestCoupleId,
      guestTeamName: guestTeamName ?? this.guestTeamName,
      gameType: gameType,
      gameMode: gameMode,
      status: status ?? this.status,
      createdAt: createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
      sessionId: sessionId ?? this.sessionId,
      hostScore: hostScore ?? this.hostScore,
      guestScore: guestScore ?? this.guestScore,
      hostCorrect: hostCorrect ?? this.hostCorrect,
      guestCorrect: guestCorrect ?? this.guestCorrect,
      hostFinished: hostFinished ?? this.hostFinished,
      guestFinished: guestFinished ?? this.guestFinished,
      hostReady: hostReady ?? this.hostReady,
      guestReady: guestReady ?? this.guestReady,
      questionCount: questionCount ?? this.questionCount,
      gameDuration: gameDuration ?? this.gameDuration,
    );
  }
}

