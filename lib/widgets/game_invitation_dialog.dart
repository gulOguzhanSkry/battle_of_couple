import 'package:flutter/material.dart';
import '../../models/game_invitation.dart';
import '../../models/game_session.dart';
import '../../services/game_service.dart';
import '../../core/constants/app_strings.dart';
import '../../enums/game_type.dart';
import '../../enums/game_mode.dart';

/// Gelen oyun daveti dialog'u - tüm oyunlarda kullanılabilir
class GameInvitationDialog extends StatefulWidget {
  final GameInvitation invitation;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const GameInvitationDialog({
    super.key,
    required this.invitation,
    this.onAccepted,
    this.onDeclined,
  });

  /// Dialog'u göster
  static Future<GameSession?> show(
    BuildContext context,
    GameInvitation invitation,
  ) async {
    return showDialog<GameSession?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameInvitationDialog(invitation: invitation),
    );
  }

  @override
  State<GameInvitationDialog> createState() => _GameInvitationDialogState();
}

class _GameInvitationDialogState extends State<GameInvitationDialog>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGameName(String gameType) {
    switch (GameType.fromString(gameType)) {
      case GameType.heartShooter:
        return AppStrings.gameTypeHeartShooter;
      case GameType.quiz:
        return AppStrings.gameTypeQuiz;
    }
  }

  String _getModeName(String gameMode) {
    switch (GameMode.fromString(gameMode)) {
      case GameMode.couplesVs:
        return AppStrings.gameModeCouplesVs;
      case GameMode.partners:
        return AppStrings.gameModePartners;
    }
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    
    final session = await _gameService.acceptInvitation(widget.invitation);
    
    if (mounted) {
      Navigator.of(context).pop(session);
      widget.onAccepted?.call();
    }
  }

  Future<void> _decline() async {
    setState(() => _isLoading = true);
    
    await _gameService.declineInvitation(widget.invitation.id);
    
    if (mounted) {
      Navigator.of(context).pop(null);
      widget.onDeclined?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.pink.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kalp ikonu (animasyonlu)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + _controller.value * 0.1,
                    child: Icon(
                      Icons.favorite,
                      size: 64,
                      color: Colors.pink.withOpacity(0.8 + _controller.value * 0.2),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Başlık
              Text(
                AppStrings.invitationTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.pink.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Davet eden
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.invitation.inviterName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.invitationText.replaceAll('%s', _getGameName(widget.invitation.gameType)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getModeName(widget.invitation.gameMode),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Butonlar
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.pink)
              else
                Row(
                  children: [
                    // Reddet
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _decline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.invitationDecline),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Kabul et
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.pink.withOpacity(0.5),
                        ),
                        child: Text(
                          AppStrings.invitationAccept,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
