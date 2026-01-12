import 'package:cloud_firestore/cloud_firestore.dart';

/// Çift takım modeli - her çift için benzersiz takım ismi
class CoupleTeam {
  final String id;           // Birleşik ID (partner1Id_partner2Id)
  final String partner1Id;
  final String partner2Id;
  final String teamName;     // Benzersiz takım ismi
  final String? teamEmoji;   // Opsiyonel emoji
  final DateTime createdAt;
  final String createdBy;    // İsmi belirleyen kişi

  const CoupleTeam({
    required this.id,
    required this.partner1Id,
    required this.partner2Id,
    required this.teamName,
    this.teamEmoji,
    required this.createdAt,
    required this.createdBy,
  });

  /// Statik ID oluştur (her zaman aynı sıralama)
  static String generateId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Firestore'dan oluştur
  factory CoupleTeam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoupleTeam(
      id: doc.id,
      partner1Id: data['partner1Id'] ?? '',
      partner2Id: data['partner2Id'] ?? '',
      teamName: data['teamName'] ?? '',
      teamEmoji: data['teamEmoji'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'partner1Id': partner1Id,
      'partner2Id': partner2Id,
      'teamName': teamName,
      'teamEmoji': teamEmoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Bu kullanıcı takımın bir parçası mı?
  bool isMember(String userId) => partner1Id == userId || partner2Id == userId;

  /// Display name (emoji varsa ekle)
  String get displayName => teamEmoji != null ? '$teamEmoji $teamName' : teamName;
}
