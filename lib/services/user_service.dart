import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/partner_request.dart';
import 'base_service.dart';

class UserService extends BaseService {
  
  // ==================== USER PROFILE METHODS ====================

  // Create user profile from Google Sign-In
  Future<void> createUserProfile(User user) async {
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      // Only create if doesn't exist
      if (!userDoc.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Kullanıcı',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
        );

        await firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toFirestore());
      }
    } catch (e) {
      logError('createUserProfile', e);
      // Silent fail or rethrow as generic exception
      throw Exception('Kullanıcı profili oluşturulurken hata: $e');
    }
  }

  /// Update user's profile photo URL
  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      logError('updateProfilePhoto', e);
      throw Exception('Profil fotoğrafı güncellenemedi.');
    }
  }

  /// Update user's display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });
    } catch (e) {
      logError('updateDisplayName', e);
      throw Exception('İsim güncellenemedi.');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc);
    } catch (e) {
      logError('getUserProfile', e);
      return null;
    }
  }

  // Get user profile stream
  Stream<UserModel?> getUserProfileStream(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null)
        .handleError((e) {
          logError('getUserProfileStream', e);
          return null;
        });
  }

  // Find user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return UserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      logError('getUserByEmail', e);
      return null;
    }
  }

  // ==================== PARTNER REQUEST SYSTEM ====================

  // Send partner request
  Future<void> sendPartnerRequest(String userId, String partnerEmail) async {
    try {
      // Email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(partnerEmail.trim().toLowerCase())) {
        throw Exception('Geçerli bir email adresi girin.');
      }

      // Get current user
      final currentUser = await getUserProfile(userId);
      if (currentUser == null) {
        throw Exception('Kullanıcı profili bulunamadı.');
      }

      // Check if already has partner
      if (currentUser.hasPartner) {
        throw Exception('Zaten bir partneriniz var. Önce mevcut bağlantıyı kaldırın.');
      }
      
      // Find partner by email
      final partner = await getUserByEmail(partnerEmail);
      
      if (partner == null) {
        throw Exception('Bu email adresiyle kayıtlı kullanıcı bulunamadı. Partner önce uygulamaya giriş yapmalı.');
      }

      // Check self-request
      if (partner.id == userId) {
        throw Exception('Kendinize istek gönderemezsiniz.');
      }

      // Check if partner already has a partner
      if (partner.hasPartner) {
        throw Exception('${partner.displayName} zaten başka bir partner ile bağlantılı.');
      }

      // Check if there's already a pending request
      final existingRequest = await firestore
          .collection('partner_requests')
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: partner.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Bu kişiye zaten bir istek gönderdiniz. Yanıt bekleyin.');
      }

      // Check if partner already sent a request to current user
      final reverseRequest = await firestore
          .collection('partner_requests')
          .where('senderId', isEqualTo: partner.id)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        throw Exception('${partner.displayName} size zaten bir istek göndermiş. Gelen isteklerinizi kontrol edin.');
      }

      // Create the request
      final request = PartnerRequest(
        id: '',
        senderId: userId,
        senderName: currentUser.displayName,
        senderEmail: currentUser.email,
        receiverId: partner.id,
        receiverEmail: partner.email,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await firestore.collection('partner_requests').add(request.toFirestore());

    } catch (e) {
      logError('sendPartnerRequest', e);
      // Re-throw if it's already an Exception we created, otherwise wrap it
      if (e is Exception) rethrow;
      throw Exception('Hata: $e');
    }
  }

  // Accept partner request
  Future<void> acceptPartnerRequest(String requestId) async {
    try {
      final requestDoc = await firestore.collection('partner_requests').doc(requestId).get();
      
      if (!requestDoc.exists) {
        throw Exception('İstek bulunamadı.');
      }

      final request = PartnerRequest.fromFirestore(requestDoc);

      if (request.status != RequestStatus.pending) {
        throw Exception('Bu istek zaten yanıtlanmış.');
      }

      // Get both users
      final sender = await getUserProfile(request.senderId);
      final receiver = await getUserProfile(request.receiverId);

      if (sender == null || receiver == null) {
        throw Exception('Kullanıcı bilgileri bulunamadı.');
      }

      // Check if either already has a partner
      if (sender.hasPartner || receiver.hasPartner) {
        // Update request status to rejected
        await firestore.collection('partner_requests').doc(requestId).update({
          'status': 'rejected',
        });
        throw Exception('Kullanıcılardan biri zaten başka bir partner ile bağlantılı.');
      }

      // Update request status
      await firestore.collection('partner_requests').doc(requestId).update({
        'status': 'accepted',
      });

      // Link both users
      await Future.wait([
        firestore.collection('users').doc(request.senderId).update({
          'partnerId': request.receiverId,
          'partnerEmail': request.receiverEmail,
        }),
        firestore.collection('users').doc(request.receiverId).update({
          'partnerId': request.senderId,
          'partnerEmail': request.senderEmail,
        }),
      ]);

      // Cancel all other pending requests for both users
      await _cancelOtherPendingRequests(request.senderId);
      await _cancelOtherPendingRequests(request.receiverId);
    } catch (e) {
      logError('acceptPartnerRequest', e);
      if (e is Exception) rethrow;
      throw Exception('İstek onaylanırken hata oluştu: $e');
    }
  }

  // Reject partner request
  Future<void> rejectPartnerRequest(String requestId) async {
    try {
      final requestDoc = await firestore.collection('partner_requests').doc(requestId).get();
      
      if (!requestDoc.exists) {
        throw Exception('İstek bulunamadı.');
      }

      await firestore.collection('partner_requests').doc(requestId).update({
        'status': 'rejected',
      });
    } catch (e) {
      logError('rejectPartnerRequest', e);
      throw Exception('İstek reddedilirken hata oluştu.');
    }
  }

  // Cancel sent request
  Future<void> cancelPartnerRequest(String requestId) async {
    try {
      await firestore.collection('partner_requests').doc(requestId).delete();
    } catch (e) {
      logError('cancelPartnerRequest', e);
      throw Exception('İstek iptal edilirken hata oluştu.');
    }
  }

  // Get incoming requests stream
  Stream<List<PartnerRequest>> getIncomingRequestsStream(String userId) {
    return firestore
        .collection('partner_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PartnerRequest.fromFirestore(doc)).toList())
        .handleError((e) {
          logError('getIncomingRequestsStream', e);
          return <PartnerRequest>[];
        });
  }

  // Get outgoing requests stream
  Stream<List<PartnerRequest>> getOutgoingRequestsStream(String userId) {
    return firestore
        .collection('partner_requests')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PartnerRequest.fromFirestore(doc)).toList())
        .handleError((e) {
          logError('getOutgoingRequestsStream', e);
          return <PartnerRequest>[];
        });
  }

  // Cancel all other pending requests helper
  Future<void> _cancelOtherPendingRequests(String userId) async {
    try {
      // Cancel outgoing
      final outgoing = await firestore
          .collection('partner_requests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in outgoing.docs) {
        await doc.reference.update({'status': 'rejected'});
      }

      // Cancel incoming
      final incoming = await firestore
          .collection('partner_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in incoming.docs) {
        await doc.reference.update({'status': 'rejected'});
      }
    } catch (e) {
      logError('_cancelOtherPendingRequests', e);
      // Non-critical background task, no need to throw
    }
  }

  // ==================== PARTNER MANAGEMENT ====================

  // Unlink partner
  Future<void> unlinkPartner(String userId) async {
    try {
      final user = await getUserProfile(userId);
      
      if (user == null || !user.hasPartner) return;

      // Remove partner link from both users
      await Future.wait([
        firestore.collection('users').doc(userId).update({
          'partnerId': FieldValue.delete(),
          'partnerEmail': FieldValue.delete(),
        }),
        firestore.collection('users').doc(user.partnerId!).update({
          'partnerId': FieldValue.delete(),
          'partnerEmail': FieldValue.delete(),
        }),
      ]);
    } catch (e) {
      logError('unlinkPartner', e);
      throw Exception('Partner bağlantısı kaldırılırken hata oluştu.');
    }
  }

  // Get partner profile
  Future<UserModel?> getPartnerProfile(String userId) async {
    try {
      final user = await getUserProfile(userId);
      
      if (user == null || !user.hasPartner) return null;

      return getUserProfile(user.partnerId!);
    } catch (e) {
      logError('getPartnerProfile', e);
      return null;
    }
  }

  // Get partner profile stream
  Stream<UserModel?> getPartnerProfileStream(String userId) async* {
    try {
      await for (final user in getUserProfileStream(userId)) {
        if (user == null || !user.hasPartner) {
          yield null;
        } else {
          yield* getUserProfileStream(user.partnerId!);
        }
      }
    } catch (e) {
      logError('getPartnerProfileStream', e);
      yield null;
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Helper to get current partner ID easily (used by other services)
  Future<String?> getPartnerId() async {
    try {
      if (!isAuthenticated) return null;
      final user = await getUserProfile(currentUserId);
      return user?.partnerId;
    } catch (e) {
      logError('getPartnerId', e);
      return null;
    }
  }
  
  /// Helper to get current partner generic data (used by other services)
  Future<Map<String, dynamic>?> getPartnerData() async {
    try {
      if (!isAuthenticated) return null;
      
      final user = await getUserProfile(currentUserId);
      if (user == null || !user.hasPartner) return null;
      
      final partner = await getUserProfile(user.partnerId!);
      if (partner == null) return null;
      
      return {
        'id': partner.id,
        'displayName': partner.displayName,
        'email': partner.email,
        'photoUrl': partner.photoUrl,
      };
    } catch (e) {
      logError('getPartnerData', e);
      return null;
    }
  }
}

