import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for storing Privacy Policy versions with full text
/// Collection: privacy_policies
class PrivacyPolicyVersion {
  final String id; // Version number e.g., "1.0", "1.1", "2.0"
  final String version;
  final DateTime createdAt;
  final DateTime? effectiveFrom;
  final bool isActive; // Currently active version
  
  // Full text content for each language
  final String contentTr; // Turkish
  final String contentEn; // English
  final String contentIt; // Italian
  
  // Metadata
  final String? createdBy; // Admin who created this version
  final String? changeLog; // What changed from previous version

  PrivacyPolicyVersion({
    required this.id,
    required this.version,
    required this.createdAt,
    this.effectiveFrom,
    this.isActive = false,
    required this.contentTr,
    required this.contentEn,
    required this.contentIt,
    this.createdBy,
    this.changeLog,
  });

  factory PrivacyPolicyVersion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrivacyPolicyVersion(
      id: doc.id,
      version: data['version'] ?? '1.0',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      effectiveFrom: data['effectiveFrom'] != null
          ? (data['effectiveFrom'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? false,
      contentTr: data['contentTr'] ?? '',
      contentEn: data['contentEn'] ?? '',
      contentIt: data['contentIt'] ?? '',
      createdBy: data['createdBy'],
      changeLog: data['changeLog'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      if (effectiveFrom != null) 'effectiveFrom': Timestamp.fromDate(effectiveFrom!),
      'isActive': isActive,
      'contentTr': contentTr,
      'contentEn': contentEn,
      'contentIt': contentIt,
      if (createdBy != null) 'createdBy': createdBy,
      if (changeLog != null) 'changeLog': changeLog,
    };
  }

  /// Get content for a specific language code
  String getContentForLanguage(String langCode) {
    switch (langCode) {
      case 'tr':
        return contentTr;
      case 'en':
        return contentEn;
      case 'it':
        return contentIt;
      default:
        return contentEn; // Default to English
    }
  }

  PrivacyPolicyVersion copyWith({
    String? id,
    String? version,
    DateTime? createdAt,
    DateTime? effectiveFrom,
    bool? isActive,
    String? contentTr,
    String? contentEn,
    String? contentIt,
    String? createdBy,
    String? changeLog,
  }) {
    return PrivacyPolicyVersion(
      id: id ?? this.id,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      isActive: isActive ?? this.isActive,
      contentTr: contentTr ?? this.contentTr,
      contentEn: contentEn ?? this.contentEn,
      contentIt: contentIt ?? this.contentIt,
      createdBy: createdBy ?? this.createdBy,
      changeLog: changeLog ?? this.changeLog,
    );
  }
}
