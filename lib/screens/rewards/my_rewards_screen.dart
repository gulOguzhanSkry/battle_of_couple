import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/custom_heart_confetti.dart';
import '../../models/reward_model.dart';
import '../../widgets/reward_card.dart';
import '../../services/reward_service.dart';

class MyRewardsScreen extends StatefulWidget {
  const MyRewardsScreen({super.key});

  @override
  State<MyRewardsScreen> createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends State<MyRewardsScreen> {
  final RewardService _rewardService = RewardService();
  final List<_ConfettiBurst> _activeBursts = [];
  String? _currentUserId;
  
  List<RewardModel>? _rewards;
  bool _isLoading = true;
  // Track which rewards are currently being scratched to prevent rebuild issues
  final Set<String> _scratchingIds = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Use stream but only take first emission, then manage locally
      final rewards = await _rewardService.getUserRewardsStream(_currentUserId!).first;
      if (mounted) {
        setState(() {
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAsScratched(String rewardId) {
    // Prevent duplicate calls
    if (_scratchingIds.contains(rewardId)) return;
    _scratchingIds.add(rewardId);
    
    // Update local state immediately
    setState(() {
      final index = _rewards?.indexWhere((r) => r.id == rewardId) ?? -1;
      if (index >= 0) {
        _rewards![index].isScratched = true;
      }
    });
    
    // Then update backend
    _rewardService.markAsScratched(rewardId).then((_) {
      _scratchingIds.remove(rewardId);
    }).catchError((e) {
      _scratchingIds.remove(rewardId);
      // ignore: avoid_print
      print('Error marking as scratched: $e');
    });
  }

  void _triggerConfettiEffect(Offset position) {
    if (_activeBursts.length > 15) return; // Limit particles

    final burstId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _activeBursts.add(_ConfettiBurst(id: burstId, position: position));
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _activeBursts.removeWhere((b) => b.id == burstId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Lütfen giriş yapın')));
    }

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Ödüllerim'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadRewards,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildContent(),
          
          // Confetti Layer
          ..._activeBursts.map((burst) => Positioned.fill(
                key: Key(burst.id),
                child: CustomHeartConfetti(
                  isPlaying: true,
                  spawnPosition: burst.position,
                  duration: const Duration(milliseconds: 1000),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rewards = _rewards ?? [];

    if (rewards.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return RewardCard(
          key: ValueKey('${reward.id}_${reward.isScratched}'),
          reward: reward,
          onScratchOffset: (globalPos) {
            _triggerConfettiEffect(globalPos);
          },
          onScratchCompleted: () {
            if (!reward.isScratched) {
              _markAsScratched(reward.id);
              _triggerConfettiEffect(MediaQuery.of(context).size.center(Offset.zero));
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.pink.shade100),
          const SizedBox(height: 16),
          Text(
            'Henüz hiç ödülün yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yarışmaları kazanarak ödül\nkazanabilirsin!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ConfettiBurst {
  final String id;
  final Offset position;
  _ConfettiBurst({required this.id, required this.position});
}

