import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/privacy_policy_version.dart';

/// Service for managing Privacy Policy versions and user consent
class PrivacyPolicyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _policiesRef => _firestore.collection('privacy_policies');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Current active version (cached)
  static const String currentVersion = '1.0';

  /// Get the currently active privacy policy
  Future<PrivacyPolicyVersion?> getCurrentPolicy() async {
    try {
      final snapshot = await _policiesRef
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return PrivacyPolicyVersion.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting current policy: $e');
      return null;
    }
  }

  /// Get a specific version of the privacy policy
  Future<PrivacyPolicyVersion?> getPolicyByVersion(String version) async {
    try {
      final snapshot = await _policiesRef.doc(version).get();
      if (!snapshot.exists) return null;
      return PrivacyPolicyVersion.fromFirestore(snapshot);
    } catch (e) {
      debugPrint('Error getting policy version: $e');
      return null;
    }
  }

  /// Get all privacy policy versions (for admin)
  Future<List<PrivacyPolicyVersion>> getAllVersions() async {
    try {
      final snapshot = await _policiesRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PrivacyPolicyVersion.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all versions: $e');
      return [];
    }
  }

  /// Create a new policy version (admin only)
  Future<void> createPolicyVersion(PrivacyPolicyVersion policy) async {
    try {
      // If this is marked as active, deactivate others first
      if (policy.isActive) {
        await _deactivateAllPolicies();
      }
      
      await _policiesRef.doc(policy.version).set(policy.toFirestore());
    } catch (e) {
      debugPrint('Error creating policy version: $e');
      throw Exception('Gizlilik politikası oluşturulamadı.');
    }
  }

  /// Set a policy version as active
  Future<void> setActiveVersion(String version) async {
    try {
      await _deactivateAllPolicies();
      await _policiesRef.doc(version).update({'isActive': true});
    } catch (e) {
      debugPrint('Error setting active version: $e');
      throw Exception('Aktif versiyon ayarlanamadı.');
    }
  }

  Future<void> _deactivateAllPolicies() async {
    final snapshot = await _policiesRef.where('isActive', isEqualTo: true).get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'isActive': false});
    }
  }

  /// Record user acceptance of privacy policy
  Future<void> acceptPrivacyPolicy({
    required String userId,
    required String version,
  }) async {
    try {
      await _usersRef.doc(userId).update({
        'privacyAccepted': true,
        'privacyAcceptedAt': FieldValue.serverTimestamp(),
        'privacyVersion': version,
      });
    } catch (e) {
      debugPrint('Error accepting privacy policy: $e');
      throw Exception('Gizlilik politikası kabul edilemedi.');
    }
  }

  /// Check if user has accepted the current version
  Future<bool> hasUserAcceptedCurrentVersion(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final accepted = data['privacyAccepted'] ?? false;
      final userVersion = data['privacyVersion'];
      
      return accepted && userVersion == currentVersion;
    } catch (e) {
      debugPrint('Error checking acceptance: $e');
      return false;
    }
  }

  /// Get list of users who accepted a specific version
  Future<int> getUsersAcceptedCount(String version) async {
    try {
      final snapshot = await _usersRef
          .where('privacyVersion', isEqualTo: version)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting accepted count: $e');
      return 0;
    }
  }
}
