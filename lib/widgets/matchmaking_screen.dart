import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/matchmaking_service.dart';
import '../services/user_service.dart';
import '../models/couple_team.dart';
import '../models/game_room.dart';
import '../enums/room_status.dart';
import 'team_name_dialog.dart';
import '../core/constants/app_strings.dart';

/// Eşleşme ekranı - oda oluştur veya otomatik eşleş
class MatchmakingScreen extends StatefulWidget {
  final String gameType;
  final String gameMode;
  final Function(String roomCode) onMatched;

  const MatchmakingScreen({
    super.key,
    required this.gameType,
    required this.gameMode,
    required this.onMatched,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  final _matchmaking = MatchmakingService();
  final _userService = UserService();
  final _roomCodeController = TextEditingController();
  
  late AnimationController _pulseController;
  
  CoupleTeam? _team;
  GameRoom? _room;
  String? _error;
  
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isJoining = false;
  bool _hasPartner = true; // Partner var mı?
  
  StreamSubscription? _roomSub;
  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadTeam();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _roomCodeController.dispose();
    _roomSub?.cancel();
    _queueSub?.cancel();
    _matchmaking.cleanup();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    // Önce partner kontrolü
    final partnerId = await _userService.getPartnerId();
    
    if (partnerId == null) {
      if (mounted) {
        setState(() {
          _hasPartner = false;
          _isLoading = false;
        });
      }
      return;
    }
    
    // Partner var, takım kontrolü
    final team = await _matchmaking.getMyTeam();
    
    if (mounted) {
      if (team != null) {
        setState(() {
          _team = team;
          _isLoading = false;
        });
      } else {
        // Takım ismi yok, dialog göster
        setState(() => _isLoading = false);
        await _showTeamNameDialog();
      }
    }
  }

  Future<void> _showTeamNameDialog() async {
    final team = await TeamNameDialog.show(context);
    if (team != null && mounted) {
      setState(() => _team = team);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    
    final room = await _matchmaking.createRoom(
      gameType: widget.gameType,
      gameMode: widget.gameMode,
    );
    
    if (room != null && mounted) {
      setState(() {
        _room = room;
        _isLoading = false;
      });
      
      // Oda durumunu dinle
      _roomSub = _matchmaking.listenToRoom(room.code).listen((updatedRoom) {
        if (updatedRoom?.status == RoomStatus.matched) {
          widget.onMatched(room.code);
        }
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _error = AppStrings.matchRoomCreationFailed;
      });
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    
    setState(() {
      _isJoining = true;
      _error = null;
    });
    
    final room = await _matchmaking.joinRoom(code);
    
    if (room != null && mounted) {
      widget.onMatched(code);
    } else if (mounted) {
      setState(() {
        _isJoining = false;
        _error = AppStrings.matchRoomNotFound;
      });
    }
  }

  Future<void> _startAutoMatch() async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    
    // Hemen eşleşme var mı?
    final roomCode = await _matchmaking.startSearching(
      gameType: widget.gameType,
      gameMode: widget.gameMode,
    );
    
    if (roomCode != null && mounted) {
      widget.onMatched(roomCode);
      return;
    }
    
    // Kuyrukta bekle
    _queueSub = _matchmaking.listenToQueue().listen((matchedCode) {
      if (matchedCode != null && mounted) {
        widget.onMatched(matchedCode);
      }
    });
  }

  Future<void> _cancelSearch() async {
    await _matchmaking.stopSearching();
    _queueSub?.cancel();
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _cancelRoom() async {
    if (_room != null) {
      await _matchmaking.cancelRoom(_room!.code);
    }
    _roomSub?.cancel();
    if (mounted) {
      setState(() => _room = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppStrings.matchTitle, style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : !_hasPartner
                ? _buildNoPartner()
                : _team == null
                    ? _buildNoTeam()
                    : _isSearching
                        ? _buildSearching()
                        : _room != null
                            ? _buildWaitingRoom()
                            : _buildOptions(),
      ),
    );
  }

  Widget _buildNoPartner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.person_add_alt_1, size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.matchPartnerRequired,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.matchPartnerRequiredDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.pink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.matchInviteFromProfile,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(AppStrings.matchBack),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTeam() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_off, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            AppStrings.matchNoTeamTitle,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showTeamNameDialog,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: Text(AppStrings.matchSetTeamName),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Takım bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: Colors.pink, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _team!.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.matchTeamNameLabel,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Otomatik eşleş butonu
          _buildOptionCard(
            icon: Icons.search,
            title: AppStrings.matchSearchOpponent,
            subtitle: AppStrings.matchAutoMatch,
            color: Colors.green,
            onTap: _startAutoMatch,
          ),
          
          const SizedBox(height: 16),
          
          // Oda oluştur butonu
          _buildOptionCard(
            icon: Icons.add_circle_outline,
            title: AppStrings.matchCreateRoom,
            subtitle: AppStrings.matchCreateRoomDesc,
            color: Colors.blue,
            onTap: _createRoom,
          ),
          
          const SizedBox(height: 16),
          
          // Odaya katıl
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.matchJoinRoom,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roomCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, letterSpacing: 2),
                        decoration: InputDecoration(
                          hintText: AppStrings.matchJoinRoomHint,
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isJoining ? null : _joinRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(AppStrings.matchJoin),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Hata mesajı
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearching() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + _pulseController.value * 0.1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1 + _pulseController.value * 0.1),
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: const Icon(Icons.search, size: 48, color: Colors.green),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.matchSearching,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _team?.displayName ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _cancelSearch,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(AppStrings.matchCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoom() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.meeting_room, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  AppStrings.matchRoomCode,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _room!.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _room!.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.matchCodeCopied),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + _pulseController.value * 0.5,
                child: Text(
                  AppStrings.matchSearchingSubtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cancelRoom,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(AppStrings.matchCancel),
          ),
        ],
      ),
    );
  }
}
