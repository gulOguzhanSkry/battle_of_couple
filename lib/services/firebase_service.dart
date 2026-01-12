import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_service.dart';
import 'user_service.dart';

class FirebaseService extends BaseService {
  final UserService _userService = UserService();


  // User ID - Authentication sonrası gerçek user ID'yi kullanıyoruz
  // BaseService.currentUserId throws exception, this returns default_user.
  // We keep this for backward compatibility for now.
  String get userId {
    final user = currentUser;
    if (user == null) {
      print('UYARI: Kullanıcı oturum açmamış! default_user kullanılıyor.');
      return 'default_user';
    }
    return user.uid;
  }

  // Get partner ID if exists
  Future<String?> get partnerId async {
    final userProfile = await _userService.getUserProfile(userId);
    return userProfile?.partnerId;
  }

  // ==================== COMMON OPERATIONS ====================
  // Additional shared methods can be added here
}
