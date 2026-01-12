import 'package:cloud_firestore/cloud_firestore.dart';

/// Oyun daveti durumları
enum InvitationStatus {
  pending,   // Beklemede
  accepted,  // Kabul edildi
  declined,  // Reddedildi
  expired,   // Süresi doldu
  cancelled, // İptal edildi
}

/// Genel oyun daveti modeli - tüm oyunlarda kullanılabilir
class GameInvitation {
  final String id;
  final String inviterId;
  final String inviteeId;
  final String inviterName;
  final String inviteeName;
  final String gameType;     // 'heart_shooter', 'quiz', vs.
  final String gameMode;     // 'couples_vs', 'partners', vs.
  final InvitationStatus status;
  final String? sessionId;   // Kabul edildiğinde oluşturulan session ID
  final DateTime createdAt;
  final DateTime? respondedAt;

  const GameInvitation({
    required this.id,
    required this.inviterId,
    required this.inviteeId,
    required this.inviterName,
    required this.inviteeName,
    required this.gameType,
    required this.gameMode,
    required this.status,
    this.sessionId,
    required this.createdAt,
    this.respondedAt,
  });

  /// Firestore'dan oluştur
  factory GameInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameInvitation(
      id: doc.id,
      inviterId: data['inviterId'] ?? '',
      inviteeId: data['inviteeId'] ?? '',
      inviterName: data['inviterName'] ?? '',
      inviteeName: data['inviteeName'] ?? '',
      gameType: data['gameType'] ?? '',
      gameMode: data['gameMode'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      sessionId: data['sessionId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'inviterName': inviterName,
      'inviteeName': inviteeName,
      'gameType': gameType,
      'gameMode': gameMode,
      'status': status.name,
      'sessionId': sessionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Kopyala ve güncelle
  GameInvitation copyWith({
    InvitationStatus? status,
    String? sessionId,
    DateTime? respondedAt,
  }) {
    return GameInvitation(
      id: id,
      inviterId: inviterId,
      inviteeId: inviteeId,
      inviterName: inviterName,
      inviteeName: inviteeName,
      gameType: gameType,
      gameMode: gameMode,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// Davet süresi doldu mu? (5 dakika)
  bool get isExpired {
    if (status != InvitationStatus.pending) return false;
    return DateTime.now().difference(createdAt).inMinutes > 5;
  }
}
