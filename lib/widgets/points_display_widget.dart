import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/couple_points.dart';
import '../services/points_service.dart';
import '../screens/leaderboard_screen.dart';
import '../core/constants/app_strings.dart';

/// Puan göstergesi widget'ı - Games ekranında kullanılabilir
class PointsDisplayWidget extends StatelessWidget {
  final bool compact;

  const PointsDisplayWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pointsService = PointsService();

    return StreamBuilder<CouplePoints?>(
      stream: pointsService.getMyPoints(),
      builder: (context, snapshot) {
        final points = snapshot.data;

        if (compact) {
          return _buildCompact(context, points);
        }
        return _buildFull(context, points);
      },
    );
  }

  Widget _buildCompact(BuildContext context, CouplePoints? points) {
    return GestureDetector(
      onTap: () => _openLeaderboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.3),
              Colors.orange.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              '${points?.totalPoints ?? 0}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, CouplePoints? points) {
    return GestureDetector(
      onTap: () => _openLeaderboard(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('🏆', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    points?.displayName ?? AppStrings.teamPoints,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildStatChip(AppStrings.pointsTotal, points?.totalPoints ?? 0),
                      _buildStatChip(AppStrings.pointsThisWeek, points?.weeklyPoints ?? 0),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.amber.shade900,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }
}
