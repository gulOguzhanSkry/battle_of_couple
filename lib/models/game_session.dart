import 'package:cloud_firestore/cloud_firestore.dart';

/// Oyun session durumları
enum SessionStatus {
  waiting,   // Oyuncular bekleniyor
  playing,   // Oyun devam ediyor
  finished,  // Oyun bitti
  abandoned, // Biri ayrıldı / bağlantı kesildi
}

/// Genel oyun session modeli - tüm oyunlarda kullanılabilir
class GameSession {
  final String id;
  final String player1Id;
  final String player2Id;
  final String player1Name;
  final String player2Name;
  final String gameType;      // 'heart_shooter', 'quiz', vs.
  final String gameMode;      // 'couples_vs', 'partners', vs.
  final SessionStatus status;
  
  // Skorlar
  final int player1Score;
  final int player2Score;
  
  // Presence (online/offline algılama)
  final DateTime? player1LastSeen;
  final DateTime? player2LastSeen;
  
  // Zaman bilgileri
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  
  // Kazanan (null = berabere veya bitmedi)
  final String? winnerId;

  const GameSession({
    required this.id,
    required this.player1Id,
    required this.player2Id,
    required this.player1Name,
    required this.player2Name,
    required this.gameType,
    required this.gameMode,
    required this.status,
    this.player1Score = 0,
    this.player2Score = 0,
    this.player1LastSeen,
    this.player2LastSeen,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.winnerId,
  });

  /// Firestore'dan oluştur
  factory GameSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSession(
      id: doc.id,
      player1Id: data['player1Id'] ?? '',
      player2Id: data['player2Id'] ?? '',
      player1Name: data['player1Name'] ?? '',
      player2Name: data['player2Name'] ?? '',
      gameType: data['gameType'] ?? '',
      gameMode: data['gameMode'] ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.waiting,
      ),
      player1Score: data['player1Score'] ?? 0,
      player2Score: data['player2Score'] ?? 0,
      player1LastSeen: (data['player1LastSeen'] as Timestamp?)?.toDate(),
      player2LastSeen: (data['player2LastSeen'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      winnerId: data['winnerId'],
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'gameType': gameType,
      'gameMode': gameMode,
      'status': status.name,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'player1LastSeen': player1LastSeen != null ? Timestamp.fromDate(player1LastSeen!) : null,
      'player2LastSeen': player2LastSeen != null ? Timestamp.fromDate(player2LastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'winnerId': winnerId,
    };
  }

  /// Ben player 1 miyim?
  bool isPlayer1(String myUserId) => player1Id == myUserId;
  
  /// Benim skorum
  int getMyScore(String myUserId) => isPlayer1(myUserId) ? player1Score : player2Score;
  
  /// Rakibin skoru
  int getOpponentScore(String myUserId) => isPlayer1(myUserId) ? player2Score : player1Score;
  
  /// Rakibin adı
  String getOpponentName(String myUserId) => isPlayer1(myUserId) ? player2Name : player1Name;
  
  /// Rakip online mı? (5 saniye içinde heartbeat varsa)
  bool isOpponentOnline(String myUserId) {
    final opponentLastSeen = isPlayer1(myUserId) ? player2LastSeen : player1LastSeen;
    if (opponentLastSeen == null) return false;
    return DateTime.now().difference(opponentLastSeen).inSeconds < 5;
  }

  /// Kopyala ve güncelle
  GameSession copyWith({
    SessionStatus? status,
    int? player1Score,
    int? player2Score,
    DateTime? player1LastSeen,
    DateTime? player2LastSeen,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? winnerId,
  }) {
    return GameSession(
      id: id,
      player1Id: player1Id,
      player2Id: player2Id,
      player1Name: player1Name,
      player2Name: player2Name,
      gameType: gameType,
      gameMode: gameMode,
      status: status ?? this.status,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player1LastSeen: player1LastSeen ?? this.player1LastSeen,
      player2LastSeen: player2LastSeen ?? this.player2LastSeen,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}
