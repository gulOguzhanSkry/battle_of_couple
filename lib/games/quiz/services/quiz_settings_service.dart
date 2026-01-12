import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'quiz_settings';

  Future<int> getMinSuccessRate(String categoryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(categoryId).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['minSuccessRate'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      // Default to 0 on error
      return 0;
    }
  }

  Future<void> updateMinSuccessRate(String categoryId, int rate) async {
    await _firestore.collection(_collection).doc(categoryId).set({
      'minSuccessRate': rate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
