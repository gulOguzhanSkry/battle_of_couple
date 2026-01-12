import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/couple_team.dart';
import '../models/game_room.dart';
import '../enums/room_status.dart';
import 'user_service.dart';
import 'base_service.dart';

/// Çift eşleştirme servisi - oda oluşturma, katılma ve otomatik eşleştirme
class MatchmakingService extends BaseService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final UserService _userService = UserService();

  // Collections
  CollectionReference get _teams => firestore.collection('coupleTeams');
  CollectionReference get _rooms => firestore.collection('gameRooms');
  CollectionReference get _queue => firestore.collection('matchmakingQueue');

  // ==================== TAKIM İSMİ İŞLEMLERİ ====================

  /// Çiftin takım ismini al
  Future<CoupleTeam?> getMyTeam() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final partnerId = await _userService.getPartnerId();
      if (partnerId == null) return null;

      final teamId = CoupleTeam.generateId(user.uid, partnerId);
      final doc = await _teams.doc(teamId).get();
      
      if (!doc.exists) return null;
      return CoupleTeam.fromFirestore(doc);
    } catch (e) {
      debugPrint('[MatchmakingService] getMyTeam error: $e');
      return null;
    }
  }

  /// Çiftin takım ismini stream olarak al
  Stream<CoupleTeam?> getMyTeamStream() async* {
    final user = currentUser;
    if (user == null) {
      yield null;
      return;
    }

    final partnerId = await _userService.getPartnerId();
    if (partnerId == null) {
      yield null;
      return;
    }

    final teamId = CoupleTeam.generateId(user.uid, partnerId);
    yield* _teams.doc(teamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CoupleTeam.fromFirestore(doc);
    });
  }

  /// Takım ismi benzersiz mi?
  Future<bool> isTeamNameAvailable(String name) async {
    try {
      final query = await _teams
          .where('teamName', isEqualTo: name.trim())
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('[MatchmakingService] isTeamNameAvailable error: $e');
      return false;
    }
  }

  /// Takım ismi oluştur (kalıcı - bir kere belirlenir)
  Future<CoupleTeam?> createTeamName(String name, {String? emoji}) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final partnerId = await _userService.getPartnerId();
      if (partnerId == null) {
        debugPrint('[MatchmakingService] No partner found');
        return null;
      }

      // Benzersizlik kontrolü
      if (!await isTeamNameAvailable(name)) {
        debugPrint('[MatchmakingService] Team name already taken');
        return null;
      }

      final teamId = CoupleTeam.generateId(user.uid, partnerId);
      
      // Zaten takım var mı?
      final existingDoc = await _teams.doc(teamId).get();
      if (existingDoc.exists) {
        debugPrint('[MatchmakingService] Team already exists');
        return CoupleTeam.fromFirestore(existingDoc);
      }

      final team = CoupleTeam(
        id: teamId,
        partner1Id: user.uid,
        partner2Id: partnerId,
        teamName: name.trim(),
        teamEmoji: emoji,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      await _teams.doc(teamId).set(team.toFirestore());
      debugPrint('[MatchmakingService] Team created: ${team.displayName}');
      
      return team;
    } catch (e) {
      debugPrint('[MatchmakingService] createTeamName error: $e');
      return null;
    }
  }

  // ==================== ODA İŞLEMLERİ ====================

  /// Oda oluştur
  Future<GameRoom?> createRoom({
    required String gameType,
    required String gameMode,
  }) async {
    try {
      final team = await getMyTeam();
      if (team == null) {
        debugPrint('[MatchmakingService] No team found, create team first');
        return null;
      }

      // Benzersiz oda kodu oluştur
      String code;
      bool codeExists;
      do {
        code = GameRoom.generateCode();
        final doc = await _rooms.doc(code).get();
        codeExists = doc.exists;
      } while (codeExists);

      final room = GameRoom(
        code: code,
        hostCoupleId: team.id,
        hostTeamName: team.displayName,
        gameType: gameType,
        gameMode: gameMode,
        status: RoomStatus.waiting,
        createdAt: DateTime.now(),
      );

      await _rooms.doc(code).set(room.toFirestore());
      debugPrint('[MatchmakingService] Room created: $code');
      
      return room;
    } catch (e) {
      debugPrint('[MatchmakingService] createRoom error: $e');
      return null;
    }
  }

  /// Odaya katıl
  Future<GameRoom?> joinRoom(String code) async {
    try {
      final team = await getMyTeam();
      if (team == null) {
        debugPrint('[MatchmakingService] No team found');
        return null;
      }

      final doc = await _rooms.doc(code.toUpperCase()).get();
      if (!doc.exists) {
        debugPrint('[MatchmakingService] Room not found: $code');
        return null;
      }

      final room = GameRoom.fromFirestore(doc);
      
      // Kendi odamıza katılamayız
      if (room.hostCoupleId == team.id) {
        debugPrint('[MatchmakingService] Cannot join own room');
        return null;
      }

      // Oda dolu mu?
      if (room.status != RoomStatus.waiting) {
        debugPrint('[MatchmakingService] Room is not available');
        return null;
      }

      // Odaya katıl
      await _rooms.doc(code.toUpperCase()).update({
        'guestCoupleId': team.id,
        'guestTeamName': team.displayName,
        'status': 'matched',
        'matchedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[MatchmakingService] Joined room: $code');
      
      // Güncel odayı döndür
      final updatedDoc = await _rooms.doc(code.toUpperCase()).get();
      return GameRoom.fromFirestore(updatedDoc);
    } catch (e) {
      debugPrint('[MatchmakingService] joinRoom error: $e');
      return null;
    }
  }

  /// Oda durumunu dinle
  Stream<GameRoom?> listenToRoom(String code) {
    return _rooms.doc(code).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameRoom.fromFirestore(doc);
    });
  }

  /// Oyun skorunu kaydet
  Future<bool> submitGameScore({
    required String roomCode,
    required int score,
    required int correctCount,
  }) async {
    try {
      final team = await getMyTeam();
      if (team == null) return false;

      final doc = await _rooms.doc(roomCode).get();
      if (!doc.exists) return false;

      final room = GameRoom.fromFirestore(doc);
      
      // Host mu guest mu?
      final isHost = room.hostCoupleId == team.id;
      
      if (isHost) {
        await _rooms.doc(roomCode).update({
          'hostScore': score,
          'hostCorrect': correctCount,
          'hostFinished': true,
        });
      } else {
        await _rooms.doc(roomCode).update({
          'guestScore': score,
          'guestCorrect': correctCount,
          'guestFinished': true,
        });
      }

      debugPrint('[MatchmakingService] Score submitted: $score');
      return true;
    } catch (e) {
      debugPrint('[MatchmakingService] submitGameScore error: $e');
      return false;
    }
  }

  /// Ben host mıyım?
  Future<bool> amIHost(String roomCode) async {
    try {
      final team = await getMyTeam();
      if (team == null) return false;

      final doc = await _rooms.doc(roomCode).get();
      if (!doc.exists) return false;

      final room = GameRoom.fromFirestore(doc);
      return room.hostCoupleId == team.id;
    } catch (e) {
      return false;
    }
  }

  /// Odayı iptal et
  Future<bool> cancelRoom(String code) async {
    try {
      await _rooms.doc(code).update({'status': 'cancelled'});
      return true;
    } catch (e) {
      debugPrint('[MatchmakingService] cancelRoom error: $e');
      return false;
    }
  }

  /// Oyuncunun hazır olduğunu işaretle
  Future<bool> markReady({
    required String roomCode,
    required int questionCount,
    required int gameDuration,
  }) async {
    try {
      final team = await getMyTeam();
      if (team == null) return false;

      final doc = await _rooms.doc(roomCode).get();
      if (!doc.exists) return false;

      final room = GameRoom.fromFirestore(doc);
      final isHost = room.hostCoupleId == team.id;

      // Host'san hem ready'i hem de oyun ayarlarını yaz
      if (isHost) {
        await _rooms.doc(roomCode).update({
          'hostReady': true,
          'questionCount': questionCount,
          'gameDuration': gameDuration,
        });
      } else {
        // Guest sadece ready işaretler
        await _rooms.doc(roomCode).update({
          'guestReady': true,
        });
      }

      debugPrint('[MatchmakingService] Marked ready: $roomCode (isHost: $isHost)');
      return true;
    } catch (e) {
      debugPrint('[MatchmakingService] markReady error: $e');
      return false;
    }
  }

  // ==================== OTOMATİK EŞLEŞME ====================

  /// Eşleşme kuyruğuna gir
  Future<String?> startSearching({
    required String gameType,
    required String gameMode,
  }) async {
    try {
      final team = await getMyTeam();
      if (team == null) {
        debugPrint('[MatchmakingService] No team found');
        return null;
      }

      // Aynı oyun için bekleyen başka çift var mı?
      final waitingQuery = await _queue
          .where('gameType', isEqualTo: gameType)
          .where('gameMode', isEqualTo: gameMode)
          .where('status', isEqualTo: 'searching')
          .limit(1)
          .get();

      if (waitingQuery.docs.isNotEmpty) {
        // Eşleşme bulundu!
        final waitingDoc = waitingQuery.docs.first;
        final waitingData = waitingDoc.data() as Map<String, dynamic>;
        
        // Kendi takımımız değilse eşleş
        if (waitingData['coupleId'] != team.id) {
          // Oda oluştur
          final room = await createRoom(gameType: gameType, gameMode: gameMode);
          if (room == null) return null;

          // Bekleyen çifti odaya ekle
          await _rooms.doc(room.code).update({
            'guestCoupleId': waitingData['coupleId'],
            'guestTeamName': waitingData['coupleName'],
            'status': 'matched',
            'matchedAt': FieldValue.serverTimestamp(),
          });

          // Bekleyen çifti güncelle
          await waitingDoc.reference.update({
            'status': 'matched',
            'matchedRoomCode': room.code,
          });

          debugPrint('[MatchmakingService] Auto-matched: ${room.code}');
          return room.code;
        }
      }

      // Bekleyen yok, kuyruğa gir
      await _queue.doc(team.id).set({
        'coupleId': team.id,
        'coupleName': team.displayName,
        'gameType': gameType,
        'gameMode': gameMode,
        'status': 'searching',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[MatchmakingService] Joined queue');
      return null; // Henüz eşleşme yok
    } catch (e) {
      debugPrint('[MatchmakingService] startSearching error: $e');
      return null;
    }
  }

  /// Kuyruk durumunu dinle (eşleşme olunca bilgilendir)
  Stream<String?> listenToQueue() async* {
    final team = await getMyTeam();
    if (team == null) {
      yield null;
      return;
    }

    yield* _queue.doc(team.id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      if (data['status'] == 'matched') {
        return data['matchedRoomCode'] as String?;
      }
      return null;
    });
  }

  /// Aramayı durdur (kuyruktan çık)
  Future<bool> stopSearching() async {
    try {
      final team = await getMyTeam();
      if (team == null) return false;

      await _queue.doc(team.id).delete();
      debugPrint('[MatchmakingService] Left queue');
      return true;
    } catch (e) {
      debugPrint('[MatchmakingService] stopSearching error: $e');
      return false;
    }
  }

  // ==================== CLEANUP ====================

  /// Servisi temizle (tüm aktif aramaları durdur)
  Future<void> cleanup() async {
    await stopSearching();
  }
}
