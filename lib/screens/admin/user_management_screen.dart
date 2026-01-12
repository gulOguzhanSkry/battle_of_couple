import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_strings.dart';

/// Detaylı Kullanıcı Yönetim Ekranı
/// Pagination, arama, filtreleme, rol değiştirme, engelleme özellikleri
import '../../widgets/user_list_selector.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _selectedUser;

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    try {
      await _firestore.collection('users').doc(user.id).update({'role': newRole});
      _showSnack('${user.displayName}: ${newRole == 'admin' ? AppStrings.roleAdmin : AppStrings.roleUser}');
      // TODO: Refresh list if possible
    } catch (e) {
      _showSnack('${AppStrings.error}: $e', isError: true);
    }
  }

  Future<void> _toggleBlockUser(UserModel user) async {
    final newStatus = !user.isBlocked;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? AppStrings.blockUser : AppStrings.unblockUser),
        content: Text(
          newStatus 
              ? '${user.displayName} ${AppStrings.blockConfirm}'
              : '${user.displayName} ${AppStrings.unblockConfirm}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.red : Colors.green,
            ),
            child: Text(newStatus ? AppStrings.blockUser : AppStrings.unblockUser), 
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(user.id).update({'isBlocked': newStatus});
        _showSnack(newStatus ? AppStrings.userBlocked : AppStrings.userUnblocked);
        // TODO: Refresh list
      } catch (e) {
        _showSnack('${AppStrings.error}: $e', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Left Panel - User List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: UserListSelector(
                    onUserSelected: (user) => setState(() => _selectedUser = user),
                    selectionMode: false,
                  ),
                ),
              ],
            ),
          ),
          // Right Panel - User Detail (if selected)
          if (_selectedUser != null)
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildUserDetailPanel(_selectedUser!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.people, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              AppStrings.users,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Refresh moved to widget inner logic or not needed
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.orange.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAdmin ? AppStrings.roleAdmin : AppStrings.roleUser,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isAdmin ? Colors.orange.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserModel user) {
    Color color;
    String text = user.statusText;
    
    if (user.isBlocked) {
      color = Colors.red;
    } else if (user.isRecentlyActive) {
      color = Colors.green;
    } else {
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailPanel(UserModel user) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Text(
                AppStrings.userDetails,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedUser = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: user.isBlocked ? Colors.red.shade100 : AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName.isNotEmpty ? user.displayName : AppStrings.labelUnknown,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRoleBadge(user.role),
                    const SizedBox(width: 8),
                    _buildStatusBadge(user),
                  ],
                ),
                const Divider(height: 32),
                
                // Info Items
                _buildInfoItem(Icons.fingerprint, AppStrings.labelId, user.id),
                _buildInfoItem(Icons.calendar_today, AppStrings.labelSignupDate, _formatDate(user.createdAt)),
                _buildInfoItem(
                  Icons.access_time, 
                  AppStrings.labelLastActive, 
                  user.lastActiveAt != null ? _formatDate(user.lastActiveAt!) : AppStrings.labelUnknown,
                ),
                _buildInfoItem(
                  Icons.favorite, 
                  AppStrings.labelMatchStatus, 
                  user.hasPartner ? '${AppStrings.statusMatched} (${user.partnerEmail ?? AppStrings.labelUnknown})' : AppStrings.statusSingle,
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _changeUserRole(user, user.role == 'admin' ? 'user' : 'admin'),
                        icon: Icon(user.role == 'admin' ? Icons.person : Icons.admin_panel_settings),
                        label: Text(user.role == 'admin' ? AppStrings.removeAdmin : AppStrings.makeAdmin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleBlockUser(user),
                        icon: Icon(user.isBlocked ? Icons.check_circle : Icons.block),
                        label: Text(user.isBlocked ? AppStrings.unblockUser : AppStrings.blockUser),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isBlocked ? Colors.green : Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
