import 'package:cloud_firestore/cloud_firestore.dart';

/// Liderlik tablosu türü
enum LeaderboardType {
  weekly,
  monthly,
  allTime,
}

/// Çift puanları modeli
class CouplePoints {
  final String teamId;
  final String teamName;
  final String? teamEmoji;
  final int totalPoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final DateTime lastUpdated;
  final int currentWeek;
  final int currentMonth;

  const CouplePoints({
    required this.teamId,
    required this.teamName,
    this.teamEmoji,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.lastUpdated,
    required this.currentWeek,
    required this.currentMonth,
  });

  String get displayName => teamEmoji != null 
      ? '$teamEmoji $teamName' 
      : teamName;

  factory CouplePoints.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouplePoints(
      teamId: doc.id,
      teamName: data['teamName'] ?? '',
      teamEmoji: data['teamEmoji'],
      totalPoints: data['totalPoints'] ?? 0,
      weeklyPoints: data['weeklyPoints'] ?? 0,
      monthlyPoints: data['monthlyPoints'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentWeek: data['currentWeek'] ?? _getCurrentWeek(),
      currentMonth: data['currentMonth'] ?? DateTime.now().month,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamName': teamName,
      'teamEmoji': teamEmoji,
      'totalPoints': totalPoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'lastUpdated': FieldValue.serverTimestamp(),
      'currentWeek': currentWeek,
      'currentMonth': currentMonth,
    };
  }

  static int _getCurrentWeek() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysDiff = now.difference(firstDayOfYear).inDays;
    return (daysDiff / 7).ceil();
  }
}

/// Puan geçmişi modeli
class PointHistory {
  final String id;
  final String teamId;
  final int points;
  final String source; // vocabulary_quiz, couple_vs_couple, etc.
  final String? description;
  final DateTime createdAt;

  const PointHistory({
    required this.id,
    required this.teamId,
    required this.points,
    required this.source,
    this.description,
    required this.createdAt,
  });

  factory PointHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointHistory(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      points: data['points'] ?? 0,
      source: data['source'] ?? 'unknown',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'points': points,
      'source': source,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get sourceDisplayName {
    switch (source) {
      case 'vocabulary_quiz': return '📚 Kelime Testi';
      case 'couple_vs_couple': return '⚔️ Çift vs Çift';
      case 'heart_shooter': return '💕 Heart Shooter';
      default: return '🎮 Oyun';
    }
  }
}
