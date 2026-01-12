import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game_invitation.dart';
import '../models/game_session.dart';
import 'user_service.dart';
import 'base_service.dart';

/// Genel oyun servisi - davet, session ve presence yönetimi
/// Tüm oyunlarda kullanılabilir (heart_shooter, quiz, vs.)
class GameService extends BaseService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final UserService _userService = UserService();
  
  // Presence timer
  Timer? _presenceTimer;
  String? _activeSessionId;
  
  // Collections
  CollectionReference get _invitations => firestore.collection('gameInvitations');
  CollectionReference get _sessions => firestore.collection('gameSessions');

  // ==================== DAVET İŞLEMLERİ ====================

  /// Oyun daveti gönder
  Future<GameInvitation?> sendInvitation({
    required String gameType,
    required String gameMode,
  }) async {
    try {
    final user = currentUser;
      if (user == null) {
        debugPrint('[GameService] No current user');
        return null;
      }

      // Partner ID'yi al
      final partnerId = await _userService.getPartnerId();
      if (partnerId == null) {
        debugPrint('[GameService] No partner found');
        return null;
      }

      // İsimlerini al
      final inviterName = user.displayName ?? 'Oyuncu';
      final partnerData = await _userService.getPartnerData();
      final inviteeName = partnerData?['displayName'] ?? 'Partner';

      // Daveti oluştur
      final docRef = _invitations.doc();
      final invitation = GameInvitation(
        id: docRef.id,
        inviterId: user.uid,
        inviteeId: partnerId,
        inviterName: inviterName,
        inviteeName: inviteeName,
        gameType: gameType,
        gameMode: gameMode,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
      );

      await docRef.set(invitation.toFirestore());
      debugPrint('[GameService] Invitation sent: ${docRef.id}');
      
      return invitation;
    } catch (e) {
      debugPrint('[GameService] sendInvitation error: $e');
      return null;
    }
  }

  /// Gelen davetleri dinle
  Stream<List<GameInvitation>> listenToMyInvitations() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _invitations
        .where('inviteeId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GameInvitation.fromFirestore(doc))
              .where((inv) => !inv.isExpired)
              .toList();
        });
  }

  /// Daveti kabul et ve session oluştur
  Future<GameSession?> acceptInvitation(GameInvitation invitation) async {
    try {
      // final currentUser = currentUser; // Not needed if we don't use it directly here except for null check?
      if (!isAuthenticated) return null;

      // Session oluştur
      final sessionRef = _sessions.doc();
      final session = GameSession(
        id: sessionRef.id,
        player1Id: invitation.inviterId,
        player2Id: invitation.inviteeId,
        player1Name: invitation.inviterName,
        player2Name: invitation.inviteeName,
        gameType: invitation.gameType,
        gameMode: invitation.gameMode,
        status: SessionStatus.waiting,
        createdAt: DateTime.now(),
      );

      // Batch yazma
      final batch = firestore.batch();
      
      // Session'ı kaydet
      batch.set(sessionRef, session.toFirestore());
      
      // Daveti güncelle
      batch.update(_invitations.doc(invitation.id), {
        'status': 'accepted',
        'sessionId': sessionRef.id,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('[GameService] Invitation accepted, session: ${sessionRef.id}');
      
      return session;
    } catch (e) {
      debugPrint('[GameService] acceptInvitation error: $e');
      return null;
    }
  }

  /// Daveti reddet
  Future<bool> declineInvitation(String invitationId) async {
    try {
      await _invitations.doc(invitationId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[GameService] Invitation declined: $invitationId');
      return true;
    } catch (e) {
      debugPrint('[GameService] declineInvitation error: $e');
      return false;
    }
  }

  /// Davet durumunu dinle (gönderen için)
  Stream<GameInvitation?> listenToInvitationStatus(String invitationId) {
    return _invitations.doc(invitationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameInvitation.fromFirestore(doc);
    });
  }

  // ==================== SESSION İŞLEMLERİ ====================

  /// Session'ı dinle
  Stream<GameSession?> listenToSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameSession.fromFirestore(doc);
    });
  }

  /// Oyunu başlat
  Future<bool> startGame(String sessionId) async {
    try {
      await _sessions.doc(sessionId).update({
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[GameService] Game started: $sessionId');
      return true;
    } catch (e) {
      debugPrint('[GameService] startGame error: $e');
      return false;
    }
  }

  /// Skoru güncelle
  Future<bool> updateScore(String sessionId, int score) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Hangi oyuncu olduğumu bul
      final doc = await _sessions.doc(sessionId).get();
      if (!doc.exists) return false;
      
      final session = GameSession.fromFirestore(doc);
      final isPlayer1 = session.isPlayer1(user.uid);
      
      // Skoru güncelle
      await _sessions.doc(sessionId).update({
        isPlayer1 ? 'player1Score' : 'player2Score': score,
      });
      
      return true;
    } catch (e) {
      debugPrint('[GameService] updateScore error: $e');
      return false;
    }
  }

  /// Oyunu bitir
  Future<bool> endGame(String sessionId, {String? winnerId}) async {
    try {
      await _sessions.doc(sessionId).update({
        'status': 'finished',
        'finishedAt': FieldValue.serverTimestamp(),
        'winnerId': winnerId,
      });
      
      // Presence timer'ı durdur
      stopPresence();
      
      debugPrint('[GameService] Game ended: $sessionId');
      return true;
    } catch (e) {
      debugPrint('[GameService] endGame error: $e');
      return false;
    }
  }

  /// Oyundan ayrıl (offline)
  Future<bool> abandonGame(String sessionId) async {
    try {
      await _sessions.doc(sessionId).update({
        'status': 'abandoned',
        'finishedAt': FieldValue.serverTimestamp(),
      });
      
      stopPresence();
      
      debugPrint('[GameService] Game abandoned: $sessionId');
      return true;
    } catch (e) {
      debugPrint('[GameService] abandonGame error: $e');
      return false;
    }
  }

  // ==================== PRESENCE SİSTEMİ ====================

  /// Presence heartbeat'i başlat (2 saniyede bir)
  void startPresence(String sessionId) {
    _activeSessionId = sessionId;
    
    // Hemen bir heartbeat gönder
    _sendHeartbeat();
    
    // Timer'ı başlat
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _sendHeartbeat();
    });
    
    debugPrint('[GameService] Presence started for session: $sessionId');
  }

  /// Presence heartbeat'i durdur
  void stopPresence() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _activeSessionId = null;
    debugPrint('[GameService] Presence stopped');
  }

  /// Heartbeat gönder
  Future<void> _sendHeartbeat() async {
    if (_activeSessionId == null) return;
    
    try {
      final user = currentUser;
      if (user == null) return;

      final doc = await _sessions.doc(_activeSessionId).get();
      if (!doc.exists) return;
      
      final session = GameSession.fromFirestore(doc);
      final isPlayer1 = session.isPlayer1(user.uid);
      
      await _sessions.doc(_activeSessionId).update({
        isPlayer1 ? 'player1LastSeen' : 'player2LastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[GameService] Heartbeat error: $e');
    }
  }

  /// Rakip online mı kontrol et (session stream'den)
  bool checkOpponentOnline(GameSession session, String myUserId) {
    return session.isOpponentOnline(myUserId);
  }

  // ==================== CLEANUP ====================

  /// Servisi temizle
  void dispose() {
    stopPresence();
  }
}
