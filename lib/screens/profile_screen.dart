import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../models/user_model.dart';
import '../models/partner_request.dart';
import '../models/couple_team.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/matchmaking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/team_name_dialog.dart';
import 'login_screen.dart';
import 'developer_options_screen.dart';
import 'rewards/my_rewards_screen.dart';
import '../widgets/profile_photo_uploader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPartnerRequest() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showError(AppStrings.enterEmail);
      return;
    }

    if (!email.contains('@')) {
      _showError(AppStrings.invalidEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser!.uid;
      await _userService.sendPartnerRequest(userId, email);

      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.partnerRequestSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest(PartnerRequest request) async {
    setState(() => _isLoading = true);

    try {
      await _userService.acceptPartnerRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.senderName} ${AppStrings.connectionEstablished}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest(PartnerRequest request) async {
    try {
      await _userService.rejectPartnerRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.requestRejected)),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _cancelRequest(PartnerRequest request) async {
    try {
      await _userService.cancelPartnerRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.requestCancelled)),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _unlinkPartner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.removePartnerTitle),
        content: Text(
          AppStrings.removePartnerContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.remove, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser!.uid;
      await _userService.unlinkPartner(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.partnerRemoved)),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.signOutTitle),
        content: Text(AppStrings.signOutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.signOut, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authService.signOut();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(AppStrings.errorTitle),
            ],
          ),
          content: SelectableText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.ok),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userModel = snapshot.data;

        if (userModel == null) {
          // Profile failed to load - show sign out option
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.profileLoadError,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(AppStrings.signOut),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Info Card
              _buildUserInfoCard(theme, userModel),
              const SizedBox(height: 16),

              // Team Name Section (Only if has partner)
              if (userModel.hasPartner) ...[
                _buildTeamNameSection(theme),
                const SizedBox(height: 24),
              ],

              // Incoming Requests Section
              _buildIncomingRequestsSection(theme, user.uid),

              // Outgoing Requests Section
              _buildOutgoingRequestsSection(theme, user.uid),

              // Partner Section
              _buildPartnerSection(theme, user.uid, userModel),

              const SizedBox(height: 24),

              // Rewards Section
              _buildRewardsSection(theme),
              const SizedBox(height: 24),

              // Language Section
              _buildLanguageSection(theme),
              const SizedBox(height: 24),

              // Developer Menu (Admins and Editors)
              if (userModel.canAccessDevTools) ...[
                _buildDeveloperSection(theme, userModel),
                const SizedBox(height: 24),
              ],
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(AppStrings.signOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, UserModel userModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfilePhotoUploader(
              userId: userModel.id,
              currentPhotoUrl: userModel.photoUrl,
              displayName: userModel.displayName,
              radius: 50,
            ),
            const SizedBox(height: 16),
            Text(
              userModel.displayName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              userModel.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamNameSection(ThemeData theme) {
    return StreamBuilder<CoupleTeam?>(
      stream: _matchmakingService.getMyTeamStream(),
      builder: (context, snapshot) {
        final team = snapshot.data;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.teamNameTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                if (team != null) ...[
                  // Takım ismi var
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.accentColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          team.teamEmoji ?? '💕',
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.teamName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                AppStrings.gameAppearance,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.verified,
                          color: AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Takım ismi yok
                  Text(
                    AppStrings.teamNameDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTeamNameDialog(),
                      icon: const Icon(Icons.edit),
                      label: Text(AppStrings.setTeamName),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTeamNameDialog() async {
    final team = await TeamNameDialog.show(context);
    
    if (team != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${team.teamEmoji ?? "💕"} ${team.teamName} ${AppStrings.teamCreated}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Widget _buildIncomingRequestsSection(ThemeData theme, String userId) {
    return StreamBuilder<List<PartnerRequest>>(
      stream: _userService.getIncomingRequestsStream(userId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Card(
              color: AppTheme.accentColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${AppStrings.incomingRequests} (${requests.length})',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...requests.map((request) => _buildIncomingRequestTile(request)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildIncomingRequestTile(PartnerRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            request.senderName.isNotEmpty ? request.senderName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(request.senderName),
        subtitle: Text(request.senderEmail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
              onPressed: _isLoading ? null : () => _acceptRequest(request),
              tooltip: AppStrings.accept,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
              onPressed: _isLoading ? null : () => _rejectRequest(request),
              tooltip: AppStrings.reject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestsSection(ThemeData theme, String userId) {
    return StreamBuilder<List<PartnerRequest>>(
      stream: _userService.getOutgoingRequestsStream(userId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.send, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.outgoingRequests,
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...requests.map((request) => _buildOutgoingRequestTile(request)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildOutgoingRequestTile(PartnerRequest request) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange,
        child: Text(
          request.receiverEmail.isNotEmpty ? request.receiverEmail[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(request.receiverEmail),
      subtitle: Text(AppStrings.waitingForResponse),
      trailing: TextButton.icon(
        icon: const Icon(Icons.close, size: 16),
        label: Text(AppStrings.cancel),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        onPressed: () => _cancelRequest(request),
      ),
    );
  }

  Widget _buildPartnerSection(ThemeData theme, String userId, UserModel userModel) {
    return StreamBuilder<UserModel?>(
      stream: _userService.getPartnerProfileStream(userId),
      builder: (context, partnerSnapshot) {
        final partner = partnerSnapshot.data;

        if (partner != null) {
          // Has Partner
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.yourPartner,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: partner.photoUrl.isNotEmpty
                          ? NetworkImage(partner.photoUrl)
                          : null,
                      child: partner.photoUrl.isEmpty
                          ? Text(partner.displayName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(partner.displayName),
                    subtitle: Text(partner.email),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _unlinkPartner,
                      icon: const Icon(Icons.link_off),
                      label:Text(AppStrings.unlink),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // No Partner - Show add partner form
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.addPartner,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.addPartnerDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppStrings.partnerEmailLabel,
                      hintText: 'ornek@gmail.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendPartnerRequest,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(AppStrings.sendRequest),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDeveloperSection(ThemeData theme, UserModel userModel) {
    final isAdmin = userModel.isAdmin;
    final bgColor = isAdmin ? Colors.red.shade50 : Colors.purple.shade50;
    final borderColor = isAdmin ? Colors.red.shade200 : Colors.purple.shade200;
    final iconColor = isAdmin ? Colors.red.shade900 : Colors.purple.shade700;
    final textColor = isAdmin ? Colors.red.shade900 : Colors.purple.shade700;
    
    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        leading: Icon(
          isAdmin ? Icons.admin_panel_settings : Icons.edit_note,
          color: iconColor,
        ),
        title: Text(
          isAdmin ? AppStrings.devPanel : AppStrings.editorPanelTitle,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isAdmin ? AppStrings.devPanelSubtitle : AppStrings.editorPanelSubtitle,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeveloperOptionsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsSection(ThemeData theme) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.card_giftcard, color: Colors.orange),
        ),
        title: const Text('Ödüllerim'),
        subtitle: const Text('Kazanılan hediye çekleri'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyRewardsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Language / Dil', 
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLanguageOption('TR', AppLanguage.turkish, '🇹🇷'),
                _buildLanguageOption('EN', AppLanguage.english, '🇬🇧'),
                _buildLanguageOption('IT', AppLanguage.italian, '🇮🇹'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, AppLanguage language, String flag) {
    final isSelected = AppStrings.currentLanguage == language;
    
    return InkWell(
      onTap: () => _changeLanguage(language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primaryColor) : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(AppLanguage language) {
    setState(() {
      AppStrings.setLanguage(language);
    });
  }
}
