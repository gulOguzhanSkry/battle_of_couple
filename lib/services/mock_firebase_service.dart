import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'base_service.dart';

class MockFirebaseService implements BaseService {
  String get userId => 'mock_user';

  @override
  FirebaseAuth get auth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  User? get currentUser => null;

  @override
  String get currentUserId => 'mock_user';

  @override
  bool get isAuthenticated => true;

  @override
  void logError(String method, dynamic error) {
    print('Mock Error [$method]: $error');
  }
}
