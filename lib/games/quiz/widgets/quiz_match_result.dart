import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/game_room.dart';

/// Multiplayer sonuç ekranı
class QuizMatchResult extends StatelessWidget {
  final GameRoom room;

  const QuizMatchResult({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final hostWon = room.hostScore > room.guestScore;
    final guestWon = room.guestScore > room.hostScore;
    final isDraw = room.hostScore == room.guestScore;
    
    String title;
    if (isDraw) {
      title = AppStrings.matchResultDraw;
    } else if (room.winnerTeamName != null) {
      title = AppStrings.matchResultWin.replaceAll('%s', room.winnerTeamName!);
    } else {
      title = AppStrings.matchResultGameOver;
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildTeamScore(room.hostTeamName, room.hostScore, room.hostCorrect, hostWon)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('VS', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: _buildTeamScore(room.guestTeamName ?? AppStrings.opponentPlaceholder, room.guestScore, room.guestCorrect, guestWon)),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                hostWon || guestWon ? AppStrings.bonusWin : AppStrings.bonusDraw,
                style: const TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScore(String teamName, int score, int correct, bool isWinner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWinner
              ? [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.2)]
              : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isWinner ? Colors.amber : Colors.white24, width: isWinner ? 2 : 1),
      ),
      child: Column(
        children: [
          if (isWinner) const Text('👑', style: TextStyle(fontSize: 24)),
          Text(
            teamName,
            style: TextStyle(color: isWinner ? Colors.amber : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text('$score', style: TextStyle(color: isWinner ? Colors.amber : Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('$correct ${AppStrings.correctCountSuffix}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }
}
