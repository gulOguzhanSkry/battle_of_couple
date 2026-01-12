import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_role.dart';
import '../core/constants/app_strings.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role; // 'user' or 'admin'
  final String? partnerId;
  final String? partnerEmail;
  final DateTime createdAt;
  
  // Status fields
  final bool isBlocked;
  final DateTime? lastActiveAt;
  
  // Privacy Policy consent tracking
  final bool privacyAccepted;
  final DateTime? privacyAcceptedAt;
  final String? privacyVersion; // e.g., "1.0"

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.role = 'user',
    this.partnerId,
    this.partnerEmail,
    required this.createdAt,
    this.isBlocked = false,
    this.lastActiveAt,
    this.privacyAccepted = false,
    this.privacyAcceptedAt,
    this.privacyVersion,
  });

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] ?? 'user',
      partnerId: data['partnerId'],
      partnerEmail: data['partnerEmail'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isBlocked: data['isBlocked'] ?? false,
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate() 
          : null,
      privacyAccepted: data['privacyAccepted'] ?? false,
      privacyAcceptedAt: data['privacyAcceptedAt'] != null 
          ? (data['privacyAcceptedAt'] as Timestamp).toDate() 
          : null,
      privacyVersion: data['privacyVersion'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'partnerId': partnerId,
      'partnerEmail': partnerEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'isBlocked': isBlocked,
      if (lastActiveAt != null) 'lastActiveAt': Timestamp.fromDate(lastActiveAt!),
      'privacyAccepted': privacyAccepted,
      if (privacyAcceptedAt != null) 'privacyAcceptedAt': Timestamp.fromDate(privacyAcceptedAt!),
      if (privacyVersion != null) 'privacyVersion': privacyVersion,
    };
  }

  // Get UserRole enum
  UserRole get userRole => UserRole.fromString(role);

  // Check if user has a partner
  bool get hasPartner => partnerId != null && partnerId!.isNotEmpty;
  
  // Check if user is admin (full access)
  bool get isAdmin => userRole.isAdmin;
  
  // Check if user is editor (question creation access only)
  bool get isEditor => userRole.isEditor;
  
  // Check if user has any elevated permissions (admin or editor)
  bool get hasElevatedAccess => userRole.hasElevatedAccess;
  
  // Check if user can access developer tools
  bool get canAccessDevTools => userRole.canAccessDevTools;
  
  // Check if user can manage users (admin only)
  bool get canManageUsers => userRole.canManageUsers;
  
  // Get role display name
  String get roleDisplayName => userRole.displayName;
  
  // Check if user is active (within last 24 hours)
  bool get isRecentlyActive {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inHours < 24;
  }
  
  // Get status text
  String get statusText {
    if (isBlocked) return AppStrings.statusBlocked;
    if (isRecentlyActive) return AppStrings.statusActive;
    return AppStrings.statusOffline;
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    String? partnerId,
    String? partnerEmail,
    DateTime? createdAt,
    bool? isBlocked,
    DateTime? lastActiveAt,
    bool? privacyAccepted,
    DateTime? privacyAcceptedAt,
    String? privacyVersion,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      partnerId: partnerId ?? this.partnerId,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      privacyAcceptedAt: privacyAcceptedAt ?? this.privacyAcceptedAt,
      privacyVersion: privacyVersion ?? this.privacyVersion,
    );
  }
  
  /// Check if user needs to accept new privacy policy version
  bool needsPrivacyAcceptance(String currentVersion) {
    if (!privacyAccepted) return true;
    if (privacyVersion == null) return true;
    return privacyVersion != currentVersion;
  }
}

