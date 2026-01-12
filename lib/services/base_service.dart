import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Base service class that provides common dependencies and helper properties.
/// All Firebase-related services should extend this class.
abstract class BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Expose dependencies to subclasses if needed, but prefer using getters below
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  /// Returns the current authenticated user or null.
  User? get currentUser => _auth.currentUser;

  /// Returns the current user's ID.
  /// Throws an exception if user is not logged in.
  String get currentUserId {
    final user = currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }
    return user.uid;
  }

  /// Returns true if a user is currently signed in.
  bool get isAuthenticated => currentUser != null;

  /// Helper for logging errors consistently
  void logError(String method, dynamic error) {
    debugPrint('[${runtimeType.toString()}] $method error: $error');
  }
}
