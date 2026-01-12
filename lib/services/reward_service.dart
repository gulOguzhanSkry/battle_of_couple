import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _templatesRef => _firestore.collection('reward_templates');
  CollectionReference get _userRewardsRef => _firestore.collection('user_rewards'); 
  // user_rewards structure: global collection with userId field? Or subcollection?
  // Let's use a global collection 'user_rewards' with 'userId' index 
  // as it's easier to query "all rewards for user X".

  /// Creates a new Reward Template (ADMIN only)
  Future<void> createTemplate(RewardModel template) async {
    try {
      await _templatesRef.doc(template.id).set(template.toJson());
    } catch (e) {
      // In production, log to Crashlytics
      debugPrint('Error creating reward template: $e');
      throw Exception('Failed to create reward template. Please try again.');
    }
  }

  /// Fetches all Reward Templates (ADMIN only)
  Future<List<RewardModel>> getTemplates() async {
    try {
      final snapshot = await _templatesRef.get();
      return snapshot.docs.map((doc) {
        return RewardModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      throw Exception('Failed to load templates.');
    }
  }

  /// Assigns a reward to a specific user (ADMIN only)
  Future<void> assignRewardToUser({
    required String userId,
    required RewardModel template,
    String? customMessage,
  }) async {
    try {
      final userRewardId = _firestore.collection('dummy').doc().id; 
      
      final userReward = template.copyWith(
        id: userRewardId,
        isScratched: false,
        message: customMessage ?? template.message,
        assignedAt: DateTime.now(),
        targetIds: [userId], // Single target
        isAssigned: true,
      );

      final data = userReward.toJson();
      // Keep 'userId' for legacy queries or easier debugging if needed, 
      // but query will rely on 'targetIds'.
      data['userId'] = userId;
      data['templateId'] = template.id; // For unassignment

      await _userRewardsRef.doc(userRewardId).set(data);
      
      // Mark original template as assigned (unique gift certificate)
      await _templatesRef.doc(template.id).update({'isAssigned': true});
      
    } catch (e) {
      debugPrint('Error assigning reward: $e');
      throw Exception('Failed to assign reward to user.');
    }
  }

  /// Assigns a reward to a Couple Team (ADMIN only)
  Future<void> assignRewardToTeam({
    required String partner1Id,
    required String partner2Id,
    required RewardModel template,
    String? customMessage,
  }) async {
    try {
      final userRewardId = _firestore.collection('dummy').doc().id;
      
      // Both partners can see this reward
      final targets = [partner1Id, partner2Id];

      final userReward = template.copyWith(
        id: userRewardId,
        isScratched: false,
        message: customMessage ?? template.message,
        assignedAt: DateTime.now(),
        targetIds: targets,
        isAssigned: true,
      );

      final data = userReward.toJson();
      // No single 'userId' here, so maybe omit or set a flag
      data['isTeamReward'] = true;
      data['templateId'] = template.id; // For unassignment

      await _userRewardsRef.doc(userRewardId).set(data);
      
      // Mark original template as assigned (unique gift certificate)
      await _templatesRef.doc(template.id).update({'isAssigned': true});
    } catch (e) {
      debugPrint('Error assigning team reward: $e');
      throw Exception('Failed to assign reward to team.');
    }
  }

  /// Fetches rewards for a specific user (checks targetIds)
  Stream<List<RewardModel>> getUserRewardsStream(String userId) {
    try {
      return _userRewardsRef
          .where('targetIds', arrayContains: userId)
          .orderBy('assignedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return RewardModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching user rewards stream: $e');
      return Stream.value([]); 
    }
  }

  /// Updates the status of a reward (e.g., marked as scratched)
  Future<void> markAsScratched(String rewardId) async {
    try {
      await _userRewardsRef.doc(rewardId).update({'isScratched': true});
    } catch (e) {
       debugPrint('Error updating reward status: $e');
       // Silent fail or throw depending on UX requirement. 
       // Since it's just local visual update confirmation, maybe log only.
    }
  }

  /// Deletes a reward template (ADMIN only)
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _templatesRef.doc(templateId).delete();
    } catch (e) {
      debugPrint('Error deleting template: $e');
      throw Exception('Şablon silinemedi.');
    }
  }

  /// Deletes an assigned reward (ADMIN only) - permanently removes
  Future<void> deleteAssignedReward(String rewardId) async {
    try {
      await _userRewardsRef.doc(rewardId).delete();
    } catch (e) {
      debugPrint('Error deleting assigned reward: $e');
      throw Exception('Ödül silinemedi.');
    }
  }

  /// Unassigns a reward - takes back from user and makes it available again
  Future<void> unassignReward({required String rewardId, required String templateId}) async {
    try {
      // Delete the user reward
      await _userRewardsRef.doc(rewardId).delete();
      
      // Mark template as available again
      await _templatesRef.doc(templateId).update({'isAssigned': false});
    } catch (e) {
      debugPrint('Error unassigning reward: $e');
      throw Exception('Hediye çeki geri alınamadı.');
    }
  }

  /// Updates an existing template (ADMIN only)
  Future<void> updateTemplate(RewardModel template) async {
    try {
      await _templatesRef.doc(template.id).update(template.toJson());
    } catch (e) {
      debugPrint('Error updating template: $e');
      throw Exception('Şablon güncellenemedi.');
    }
  }

  /// Fetches all assigned rewards (for assignment history)
  Stream<List<Map<String, dynamic>>> getAllAssignedRewardsStream() {
    try {
      return _userRewardsRef
          .orderBy('assignedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching all assigned rewards: $e');
      return Stream.value([]);
    }
  }
}

// Add debugPrint since we don't have a logger setup visible in context yet
void debugPrint(String message) {
  // ignore: avoid_print
  print('[RewardService] $message');
}
