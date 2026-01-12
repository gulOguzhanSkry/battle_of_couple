import 'package:flutter/material.dart';
import '../models/couple_points.dart';
import '../services/points_service.dart';
import '../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'leaderboard/widgets/leaderboard_widgets.dart';

/// Liderlik tablosu ekranı
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PointsService _pointsService = PointsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.leaderboardBgStart,
              AppTheme.leaderboardBgMiddle,
              AppTheme.leaderboardBgEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildMyPointsSection(),
              _buildTabs(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            AppStrings.leaderboardTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMyPointsSection() {
    return StreamBuilder<CouplePoints?>(
      stream: _pointsService.getMyPoints(),
      builder: (context, snapshot) {
        return MyPointsCard(points: snapshot.data);
      },
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          return Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                // Animated indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: _tabController.index * (MediaQuery.of(context).size.width - 32) / 3,
                  top: 4,
                  bottom: 4,
                  width: (MediaQuery.of(context).size.width - 32) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.goldRank, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldRank.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab buttons
                Row(
                  children: [
                    _buildTabButton(0, '📅', AppStrings.weekly),
                    _buildTabButton(1, '📆', AppStrings.monthly),
                    _buildTabButton(2, '🏆', AppStrings.allTime),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String icon, String label) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: isSelected ? 16 : 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaderboardList(LeaderboardType.weekly),
        _buildLeaderboardList(LeaderboardType.monthly),
        _buildLeaderboardList(LeaderboardType.allTime),
      ],
    );
  }

  Widget _buildLeaderboardList(LeaderboardType type) {
    return StreamBuilder<List<CouplePoints>>(
      stream: _pointsService.getLeaderboard(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final rank = index + 1;
            final points = _getPointsForType(team, type);

            return LeaderboardRankCard(
              rank: rank,
              team: team,
              points: points,
            );
          },
        );
      },
    );
  }

  int _getPointsForType(CouplePoints team, LeaderboardType type) {
    switch (type) {
      case LeaderboardType.weekly:
        return team.weeklyPoints;
      case LeaderboardType.monthly:
        return team.monthlyPoints;
      case LeaderboardType.allTime:
        return team.totalPoints;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            AppStrings.noPointsYet,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.playToWin,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
