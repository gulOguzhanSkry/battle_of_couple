import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../models/couple_team.dart';
import '../core/constants/app_strings.dart';

/// Takım ismi belirleme dialog'u - kalıcı, onaylı
class TeamNameDialog extends StatefulWidget {
  const TeamNameDialog({super.key});

  /// Dialog'u göster ve takım ismini al
  static Future<CoupleTeam?> show(BuildContext context) {
    return showDialog<CoupleTeam?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TeamNameDialog(),
    );
  }

  @override
  State<TeamNameDialog> createState() => _TeamNameDialogState();
}

class _TeamNameDialogState extends State<TeamNameDialog> {
  final _controller = TextEditingController();
  final _matchmaking = MatchmakingService();
  
  String? _selectedEmoji;
  bool _isChecking = false;
  bool _isAvailable = true;
  bool _isCreating = false;
  String? _errorMessage;

  final _emojis = ['❤️', '💕', '💗', '💖', '💘', '💝', '🌹', '🦋', '⭐', '🌙'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability(String name) async {
    if (name.trim().length < 3) {
      setState(() {
        _isAvailable = false;
        _errorMessage = AppStrings.teamNameMinChars;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final available = await _matchmaking.isTeamNameAvailable(name.trim());

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isAvailable = available;
        _errorMessage = available ? null : AppStrings.teamNameTaken;
      });
    }
  }

  Future<void> _createTeam() async {
    final name = _controller.text.trim();
    if (name.length < 3 || !_isAvailable) return;

    // Onay dialog'u
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.teamNameConfirmTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.teamNameConfirmDesc,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.withOpacity(0.3)),
              ),
              child: Text(
                _selectedEmoji != null ? '$_selectedEmoji $name' : name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCreating = true);

    final team = await _matchmaking.createTeamName(name, emoji: _selectedEmoji);

    if (mounted) {
      if (team != null) {
        Navigator.pop(context, team);
      } else {
        setState(() {
          _isCreating = false;
          _errorMessage = AppStrings.teamNameCreateFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.pink.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              const Icon(Icons.group, color: Colors.pink, size: 48),
              const SizedBox(height: 12),
              Text(
                AppStrings.teamNameDialogTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.teamNameDialogDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 24),

              // Emoji seçimi
              Wrap(
                spacing: 8,
                children: _emojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = isSelected ? null : emoji),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(color: Colors.pink)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // İsim girişi
              TextField(
                controller: _controller,
                maxLength: 20,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: AppStrings.teamNameHint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.pink),
                  ),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  suffixIcon: _isChecking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                          ),
                        )
                      : _controller.text.length >= 3
                          ? Icon(
                              _isAvailable ? Icons.check_circle : Icons.error,
                              color: _isAvailable ? Colors.green : Colors.red,
                            )
                          : null,
                ),
                onChanged: (value) {
                  if (value.trim().length >= 3) {
                    _checkAvailability(value);
                  }
                },
              ),

              // Hata mesajı
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating || !_isAvailable || _controller.text.trim().length < 3
                          ? null
                          : _createTeam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.pink.withOpacity(0.3),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(AppStrings.teamNameCreate, style: const TextStyle(fontWeight: FontWeight.bold)),
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
