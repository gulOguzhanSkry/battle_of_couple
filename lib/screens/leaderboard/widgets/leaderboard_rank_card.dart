import 'package:flutter/material.dart';
import '../../../models/couple_points.dart';
import '../../../theme/app_theme.dart';

/// A card widget displaying a team's rank on the leaderboard
/// 
/// Shows rank (with medal for top 3), team name, and points.
/// Different styling for top 3 vs other ranks.
class LeaderboardRankCard extends StatelessWidget {
  final int rank;
  final CouplePoints team;
  final int points;

  const LeaderboardRankCard({
    super.key,
    required this.rank,
    required this.team,
    required this.points,
  });

  Color get _rankColor {
    switch (rank) {
      case 1: return AppTheme.goldRank;
      case 2: return AppTheme.silverRank;
      case 3: return AppTheme.bronzeRank;
      default: return Colors.white54;
    }
  }

  String get _rankIcon {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  bool get _isTopThree => rank <= 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isTopThree
            ? _rankColor.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isTopThree
              ? _rankColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(),
          const SizedBox(width: 12),
          Expanded(child: _buildTeamName()),
          _buildPointsBadge(),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _rankColor.withValues(alpha: 0.2),
      ),
      child: Center(
        child: _isTopThree
            ? Text(_rankIcon, style: const TextStyle(fontSize: 20))
            : Text(
                '$rank',
                style: TextStyle(
                  color: _rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTeamName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$points',
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
