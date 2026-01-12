import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/marimo.dart';
import '../../../services/user_service.dart';

/// Marimo servisi - bakım, büyüme ve durum yönetimi
class MarimoService {
  static final MarimoService _instance = MarimoService._internal();
  factory MarimoService() => _instance;
  MarimoService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Günlük yem limiti
  static const int dailyFoodLimit = 3;
  static const String _foodCountKey = 'marimo_food_count';
  static const String _foodDateKey = 'marimo_food_date';

  CollectionReference get _marimos => _firestore.collection('marimos');
  
  // ==================== CRUD ====================

  /// Çiftin marimo'sunu getir (yoksa oluştur)
  Future<Marimo?> getOrCreateMarimo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final partnerId = await _userService.getPartnerId();
      if (partnerId == null) {
        debugPrint('[MarimoService] No partner found');
        return null;
      }

      // CoupleId oluştur (her iki user id'nin sıralı birleşimi)
      final ids = [user.uid, partnerId]..sort();
      final coupleId = ids.join('_');

      // Mevcut marimo ara
      final query = await _marimos
          .where('coupleId', isEqualTo: coupleId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var marimo = Marimo.fromFirestore(query.docs.first);
        // Decay uygula ve güncelle
        marimo = _applyDecay(marimo);
        await _updateMarimo(marimo);
        return marimo;
      }

      // Yeni marimo oluştur
      final newMarimo = Marimo.create(coupleId: coupleId);
      final docRef = await _marimos.add(newMarimo.toFirestore());
      
      debugPrint('[MarimoService] Created new Marimo: ${docRef.id}');
      return Marimo.fromFirestore(await docRef.get());
    } catch (e) {
      debugPrint('[MarimoService] getOrCreateMarimo error: $e');
      return null;
    }
  }

  /// Marimo'yu dinle (real-time updates)
  Stream<Marimo?> listenToMarimo() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    final partnerId = await _userService.getPartnerId();
    if (partnerId == null) {
      yield null;
      return;
    }

    final ids = [user.uid, partnerId]..sort();
    final coupleId = ids.join('_');

    yield* _marimos
        .where('coupleId', isEqualTo: coupleId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      var marimo = Marimo.fromFirestore(snapshot.docs.first);
      return _applyDecay(marimo);
    });
  }

  /// Marimo güncelle
  Future<bool> _updateMarimo(Marimo marimo) async {
    try {
      await _marimos.doc(marimo.id).update(marimo.copyWith(
        updatedAt: DateTime.now(),
      ).toFirestore());
      return true;
    } catch (e) {
      debugPrint('[MarimoService] _updateMarimo error: $e');
      return false;
    }
  }

  // ==================== AKSİYONLAR ====================

  /// Su değiştir
  Future<bool> changeWater() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final marimo = await getOrCreateMarimo();
      if (marimo == null || marimo.isDead) return false;

      final userProfile = await _userService.getUserProfile(user.uid);
      final userName = userProfile?.displayName ?? 'Kullanıcı';

      // Su kalitesini yenile ve XP ekle
      final updated = marimo.copyWith(
        waterQuality: 100,
        lastWaterChange: DateTime.now(),
        lastWaterChangedBy: userName,
        experience: marimo.experience + 10,
        health: (marimo.health + 5).clamp(0, 100),
      );

      // Büyüme kontrolü
      final grownMarimo = _checkGrowth(updated);

      await _updateMarimo(grownMarimo);

      // Aksiyon geçmişine ekle
      await _logAction(marimo.id, MarimoActionType.changeWater, user.uid, userName);

      debugPrint('[MarimoService] Water changed by $userName');
      return true;
    } catch (e) {
      debugPrint('[MarimoService] changeWater error: $e');
      return false;
    }
  }

  /// Besin ekle
  Future<bool> addFood() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final marimo = await getOrCreateMarimo();
      if (marimo == null || marimo.isDead) return false;

      final userProfile = await _userService.getUserProfile(user.uid);
      final userName = userProfile?.displayName ?? 'Kullanıcı';

      // Besin seviyesini yenile ve XP ekle
      final updated = marimo.copyWith(
        foodLevel: 100,
        lastFed: DateTime.now(),
        lastFedBy: userName,
        experience: marimo.experience + 15,
        health: (marimo.health + 10).clamp(0, 100),
      );

      // Büyüme kontrolü
      final grownMarimo = _checkGrowth(updated);

      await _updateMarimo(grownMarimo);

      // Aksiyon geçmişine ekle
      await _logAction(marimo.id, MarimoActionType.addFood, user.uid, userName);

      debugPrint('[MarimoService] Food added by $userName');
      return true;
    } catch (e) {
      debugPrint('[MarimoService] addFood error: $e');
      return false;
    }
  }

  /// Aksiyon geçmişini kaydet
  Future<void> _logAction(String marimoId, MarimoActionType type, String userId, String userName) async {
    try {
      await _marimos.doc(marimoId).collection('actions').add(
        MarimoAction(
          id: '',
          type: type,
          userId: userId,
          userName: userName,
          timestamp: DateTime.now(),
        ).toFirestore(),
      );
    } catch (e) {
      debugPrint('[MarimoService] _logAction error: $e');
    }
  }

  /// Son aksiyonları getir
  Future<List<MarimoAction>> getRecentActions(String marimoId, {int limit = 10}) async {
    try {
      final snapshot = await _marimos
          .doc(marimoId)
          .collection('actions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => MarimoAction.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[MarimoService] getRecentActions error: $e');
      return [];
    }
  }

  // ==================== DECAY SİSTEMİ ====================

  /// Zamanla azalan değerleri uygula
  Marimo _applyDecay(Marimo marimo) {
    if (marimo.isDead) return marimo;

    final now = DateTime.now();
    
    // Su kalitesi: Saatte 4 puan düşer (~25 saatte sıfırlanır)
    final waterHours = now.difference(marimo.lastWaterChange).inHours;
    final waterDecay = waterHours * 4;
    final newWaterQuality = (marimo.waterQuality - waterDecay).clamp(0, 100);

    // Besin: Saatte 5 puan düşer (~20 saatte sıfırlanır, günde 2-3 yem lazım)
    final foodHours = now.difference(marimo.lastFed).inHours;
    final foodDecay = foodHours * 5;
    final newFoodLevel = (marimo.foodLevel - foodDecay).clamp(0, 100);

    // Sağlık: Su ve besin düşükse sağlık da düşer
    int healthPenalty = 0;
    if (newWaterQuality < 30) healthPenalty += 8;
    if (newFoodLevel < 30) healthPenalty += 8;
    if (newWaterQuality < 10) healthPenalty += 15;
    if (newFoodLevel < 10) healthPenalty += 15;
    
    final newHealth = (marimo.health - healthPenalty).clamp(0, 100);

    // Ölüm kontrolü
    final isDead = newHealth <= 0;

    return marimo.copyWith(
      waterQuality: newWaterQuality,
      foodLevel: newFoodLevel,
      health: newHealth,
      isDead: isDead,
    );
  }

  // ==================== BÜYÜME SİSTEMİ ====================

  /// Büyüme kontrolü
  Marimo _checkGrowth(Marimo marimo) {
    if (marimo.stage.next == null) return marimo; // Zaten max seviye

    if (marimo.experience >= marimo.experienceForNextStage) {
      // Seviye atla!
      final excessXP = marimo.experience - marimo.experienceForNextStage;
      return marimo.copyWith(
        stage: marimo.stage.next,
        experience: excessXP,
      );
    }

    return marimo;
  }

  // ==================== İSİM DEĞİŞTİRME ====================

  /// Marimo'nun ismini değiştir
  Future<bool> renameMarimo(String newName) async {
    try {
      final marimo = await getOrCreateMarimo();
      if (marimo == null) return false;

      await _marimos.doc(marimo.id).update({'name': newName});
      return true;
    } catch (e) {
      debugPrint('[MarimoService] renameMarimo error: $e');
      return false;
    }
  }

  // ==================== MARIMO'YU YENİDEN BAŞLAT ====================

  /// Ölen marimo'yu yeniden başlat
  Future<bool> restartMarimo() async {
    try {
      final marimo = await getOrCreateMarimo();
      if (marimo == null) return false;

      final now = DateTime.now();
      await _marimos.doc(marimo.id).update({
        'stage': MarimoStage.seed.name,
        'health': 100,
        'experience': 0,
        'waterQuality': 100,
        'foodLevel': 100,
        'lastWaterChange': Timestamp.fromDate(now),
        'lastFed': Timestamp.fromDate(now),
        'isDead': false,
        'updatedAt': Timestamp.fromDate(now),
      });

      debugPrint('[MarimoService] Marimo restarted');
      return true;
    } catch (e) {
      debugPrint('[MarimoService] restartMarimo error: $e');
      return false;
    }
  }
  // --- DEBUG METHODS ---
  
  /// Debug: Marimo'yu belirli bir aşamaya zorla
  Future<void> debugSetStage(String marimoId, int stageIndex) async {
    final marimoDoc = await _firestore.collection('marimos').doc(marimoId).get();
    if (!marimoDoc.exists) return;

    final currentMarimo = Marimo.fromFirestore(marimoDoc);
    
    // İstenen aşamayı bul (Index 1-based geliyor, enum 0-based)
    // stageIndex 1 ise Seed (index 0)
    final targetStage = MarimoStage.values.firstWhere(
      (s) => s.level == stageIndex,
      orElse: () => MarimoStage.magnificent,
    );

    // O aşama için gereken minimum XP'yi hesapla
    int targetXp = 0;
    for (var stage in MarimoStage.values) {
      if (stage.index < targetStage.index) {
        targetXp += stage.requiredXp; 
      } else {
        break;
      }
    }
    
    // Biraz fazlasını ekle
    targetXp += 10;

    await _updateMarimo(currentMarimo.copyWith(
      stage: targetStage, // Aşamayı direkt ayarla!
      experience: targetXp,
      health: 100, // Level atlayınca iyileşsin
    ));
  }

  /// Debug: Sağlığı azalt
  Future<void> debugDamage(String marimoId, int damage) async {
    final marimoDoc = await _firestore.collection('marimos').doc(marimoId).get();
    if (!marimoDoc.exists) return;

    final currentMarimo = Marimo.fromFirestore(marimoDoc);
    final newHealth = (currentMarimo.health - damage).clamp(0, 100);

    await _updateMarimo(currentMarimo.copyWith(health: newHealth));
  }

  // ==================== YEM LİMİT SİSTEMİ ====================

  /// Bugün kalan yem sayısını getir
  Future<int> getRemainingFood() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_foodDateKey) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    if (savedDate != today) {
      // Yeni gün, limiti sıfırla
      await prefs.setString(_foodDateKey, today);
      await prefs.setInt(_foodCountKey, dailyFoodLimit);
      return dailyFoodLimit;
    }
    
    return prefs.getInt(_foodCountKey) ?? dailyFoodLimit;
  }

  /// Yem kullan (true: başarılı, false: yem bitti)
  Future<bool> consumeFood() async {
    final remaining = await getRemainingFood();
    if (remaining <= 0) return false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_foodCountKey, remaining - 1);
    return true;
  }

  /// Bonus yem ekle (reklam izleyince)
  Future<void> addBonusFood(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_foodCountKey) ?? 0;
    await prefs.setInt(_foodCountKey, current + amount);
  }
}
