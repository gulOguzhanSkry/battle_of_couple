import 'package:flutter/material.dart';
import '../../../models/couple_points.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_theme.dart';

/// A card widget displaying the current user's points summary
/// 
/// Shows team name, total points, and weekly/monthly breakdown.
class MyPointsCard extends StatelessWidget {
  final CouplePoints? points;

  const MyPointsCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.accentColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildStarIcon(),
          const SizedBox(width: 16),
          Expanded(child: _buildTeamInfo()),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildStarIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Text('⭐', style: TextStyle(fontSize: 24)),
    );
  }

  Widget _buildTeamInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          points?.displayName ?? AppStrings.noTeam,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.total}: ${points?.totalPoints ?? 0} ${AppStrings.points}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildMiniStat(AppStrings.thisWeek, points?.weeklyPoints ?? 0),
        const SizedBox(height: 4),
        _buildMiniStat(AppStrings.thisMonth, points?.monthlyPoints ?? 0),
      ],
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
