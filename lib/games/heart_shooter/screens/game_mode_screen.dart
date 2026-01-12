import 'package:flutter/material.dart';
import 'dart:math';
import '../../../services/game_service.dart';
import '../../../models/game_invitation.dart';
import '../../../models/game_session.dart';
import '../../../core/constants/app_strings.dart';
import '../game_constants.dart';
import 'heart_shooter_game_screen.dart';

/// Oyun modu seçim ekranı
class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _hoveredIndex;
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMode(GameMode mode) async {
    // Couples VS için partnere davet gönder
    if (mode == GameMode.couplesVs) {
      await _handleCouplesVsMode();
      return;
    }
    
    // Solo ve Partners için direkt oyuna git
    _navigateToGame(mode);
  }
  
  Future<void> _handleCouplesVsMode() async {
    // Davet gönder
    final invitation = await _gameService.sendInvitation(
      gameType: 'heart_shooter',
      gameMode: 'couples_vs',
    );
    
    if (invitation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.hsInviteFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Bekleme dialog'unu göster
    if (mounted) {
      _showWaitingDialog(invitation);
    }
  }
  
  void _showWaitingDialog(GameInvitation invitation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WaitingForPartnerDialog(
        invitation: invitation,
        onSessionCreated: (session) {
          Navigator.of(context).pop();
          _navigateToGame(
            GameMode.couplesVs,
            sessionId: session.id,
          );
        },
        onCancelled: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  void _navigateToGame(GameMode mode, {String? sessionId}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return HeartShooterGameScreen(
            gameMode: mode,
            sessionId: sessionId,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: GameConstants.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title
              _buildTitle(),

              const SizedBox(height: 40),

              // Game mode cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeCard(
                        index: 0,
                        mode: GameMode.solo,
                        title: AppStrings.hsModeSolo,
                        subtitle: AppStrings.hsModeSoloDesc,
                        description: AppStrings.hsModeSoloDetail,
                        icon: Icons.person,
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF2E7D32),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildModeCard(
                        index: 1,
                        mode: GameMode.partners,
                        title: AppStrings.hsModePartners,
                        subtitle: AppStrings.hsModePartnersDesc,
                        description: AppStrings.hsModePartnersDetail,
                        icon: Icons.favorite,
                        colors: [
                          const Color(0xFF9C27B0),
                          const Color(0xFF7B1FA2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Animated heart icon
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + 0.1 * (0.5 + 0.5 * sin(_controller.value * 2 * pi).abs());
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      GameConstants.normalHeartColor.withOpacity(0.8),
                      GameConstants.normalHeartColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameConstants.normalHeartColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Title text
        Text(
          AppStrings.hsTitle,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.pinkAccent,
                blurRadius: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          AppStrings.hsSelectMode,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required int index,
    required GameMode mode,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> colors,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => _selectMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(isHovered ? 1.02 : 1.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(isHovered ? 0.6 : 0.4),
                  blurRadius: isHovered ? 20 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Partner bekleme dialog'u
class _WaitingForPartnerDialog extends StatefulWidget {
  final GameInvitation invitation;
  final Function(GameSession) onSessionCreated;
  final VoidCallback onCancelled;

  const _WaitingForPartnerDialog({
    required this.invitation,
    required this.onSessionCreated,
    required this.onCancelled,
  });

  @override
  State<_WaitingForPartnerDialog> createState() => _WaitingForPartnerDialogState();
}

class _WaitingForPartnerDialogState extends State<_WaitingForPartnerDialog>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _controller;
  late Stream<GameInvitation?> _invitationStream;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Davet durumunu dinle
    _invitationStream = _gameService.listenToInvitationStatus(widget.invitation.id);
    _invitationStream.listen((invitation) {
      if (invitation == null) return;
      
      if (invitation.status == InvitationStatus.accepted && invitation.sessionId != null) {
        // Session oluşturuldu, oyuna git
        _gameService.listenToSession(invitation.sessionId!).first.then((session) {
          if (session != null && mounted) {
            widget.onSessionCreated(session);
          }
        });
      } else if (invitation.status == InvitationStatus.declined) {
        // Reddedildi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.invitation.inviteeName} ${AppStrings.hsInviteDeclined}'),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onCancelled();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.pink.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading indicator
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * 3.14159,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink,
                          width: 3,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            Colors.pink.withOpacity(0),
                            Colors.pink,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.pink,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              Text(
                AppStrings.hsWaitingPartner,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '${widget.invitation.inviteeName} ${AppStrings.hsWaitingPartnerDesc}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // İptal butonu
              OutlinedButton(
                onPressed: widget.onCancelled,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppStrings.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
