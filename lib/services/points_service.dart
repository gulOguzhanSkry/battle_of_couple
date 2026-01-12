import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/couple_points.dart';
import 'matchmaking_service.dart';
import 'base_service.dart';

/// Global puan servisi - tüm oyunlar buraya puan ekler
class PointsService extends BaseService {
  static final PointsService _instance = PointsService._internal();
  factory PointsService() => _instance;
  PointsService._internal();

  final MatchmakingService _matchmaking = MatchmakingService();

  CollectionReference get _points => firestore.collection('couplePoints');
  CollectionReference get _history => firestore.collection('pointHistory');

  // ==================== PUAN EKLEME ====================

  /// Çifte puan ekle
  Future<bool> addPoints({
    required int points,
    required String source,
    String? description,
  }) async {
    try {
      final team = await _matchmaking.getMyTeam();
      if (team == null) {
        debugPrint('[PointsService] No team found');
        return false;
      }

      // Mevcut puanları al veya oluştur
      final docRef = _points.doc(team.id);
      final doc = await docRef.get();
      
      final now = DateTime.now();
      final currentWeek = _getCurrentWeek();
      final currentMonth = now.month;

      if (doc.exists) {
        final existing = CouplePoints.fromFirestore(doc);
        
        // Haftalık/aylık sıfırlama kontrolü
        int newWeekly = existing.weeklyPoints;
        int newMonthly = existing.monthlyPoints;
        
        if (existing.currentWeek != currentWeek) {
          newWeekly = 0; // Yeni hafta, sıfırla
        }
        if (existing.currentMonth != currentMonth) {
          newMonthly = 0; // Yeni ay, sıfırla
        }
        
        await docRef.update({
          'totalPoints': FieldValue.increment(points),
          'weeklyPoints': newWeekly + points,
          'monthlyPoints': newMonthly + points,
          'lastUpdated': FieldValue.serverTimestamp(),
          'currentWeek': currentWeek,
          'currentMonth': currentMonth,
        });
      } else {
        // İlk puan kaydı
        await docRef.set({
          'teamName': team.teamName,
          'teamEmoji': team.teamEmoji,
          'totalPoints': points,
          'weeklyPoints': points,
          'monthlyPoints': points,
          'lastUpdated': FieldValue.serverTimestamp(),
          'currentWeek': currentWeek,
          'currentMonth': currentMonth,
        });
      }

      // Geçmişe kaydet
      await _history.add({
        'teamId': team.id,
        'points': points,
        'source': source,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[PointsService] Added $points points from $source');
      return true;
    } catch (e) {
      debugPrint('[PointsService] addPoints error: $e');
      return false;
    }
  }

  // ==================== LİDERLİK TABLOSU ====================

  /// Liderlik tablosunu al (stream)
  Stream<List<CouplePoints>> getLeaderboard(LeaderboardType type, {int limit = 20}) {
    String orderField;
    switch (type) {
      case LeaderboardType.weekly:
        orderField = 'weeklyPoints';
        break;
      case LeaderboardType.monthly:
        orderField = 'monthlyPoints';
        break;
      case LeaderboardType.allTime:
        orderField = 'totalPoints';
        break;
    }

    return _points
        .orderBy(orderField, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CouplePoints.fromFirestore(doc))
            .toList());
  }

  /// Kendi puanlarımızı al
  Stream<CouplePoints?> getMyPoints() async* {
    final team = await _matchmaking.getMyTeam();
    if (team == null) {
      yield null;
      return;
    }

    yield* _points.doc(team.id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CouplePoints.fromFirestore(doc);
    });
  }

  /// Kendi sıramamızı al
  Future<int> getMyRank(LeaderboardType type) async {
    try {
      final team = await _matchmaking.getMyTeam();
      if (team == null) return -1;

      final myDoc = await _points.doc(team.id).get();
      if (!myDoc.exists) return -1;

      final myPoints = CouplePoints.fromFirestore(myDoc);
      
      String field;
      int myScore;
      switch (type) {
        case LeaderboardType.weekly:
          field = 'weeklyPoints';
          myScore = myPoints.weeklyPoints;
          break;
        case LeaderboardType.monthly:
          field = 'monthlyPoints';
          myScore = myPoints.monthlyPoints;
          break;
        case LeaderboardType.allTime:
          field = 'totalPoints';
          myScore = myPoints.totalPoints;
          break;
      }

      // Bizden yüksek puanlıları say
      final higherCount = await _points
          .where(field, isGreaterThan: myScore)
          .count()
          .get();

      return (higherCount.count ?? 0) + 1;
    } catch (e) {
      debugPrint('[PointsService] getMyRank error: $e');
      return -1;
    }
  }

  // ==================== GEÇMİŞ ====================

  /// Puan geçmişini al
  Stream<List<PointHistory>> getMyHistory({int limit = 20}) async* {
    final team = await _matchmaking.getMyTeam();
    if (team == null) {
      yield [];
      return;
    }

    yield* _history
        .where('teamId', isEqualTo: team.id)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointHistory.fromFirestore(doc))
            .toList());
  }

  // ==================== YARDIMCI ====================

  int _getCurrentWeek() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysDiff = now.difference(firstDayOfYear).inDays;
    return (daysDiff / 7).ceil();
  }
}
