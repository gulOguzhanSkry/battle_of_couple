import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import 'user_management_screen.dart';
import '../../widgets/scrolling_text.dart';
import 'quiz_configuration_screen.dart';

/// Modern Admin Dashboard - Tab-based yönetim paneli
/// Dashboard: İstatistikler, Kullanıcılar: Liste + Arama, Çiftler: Eşleşmeler
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Dashboard Statistics
  int _totalUsers = 0;
  int _totalCouples = 0;
  int _totalQuestions = 0;
  int _totalAdmins = 0;
  bool _isLoadingStats = true;
  
  // Users Tab
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoadingUsers = true;
  final _searchController = TextEditingController();
  String _roleFilter = 'all'; // 'all', 'user', 'admin'
  
  // Couples Tab
  List<Map<String, UserModel>> _couples = [];
  bool _isLoadingCouples = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStatistics(),
      _loadUsers(),
      _loadCouples(),
    ]);
  }

  Future<void> _loadStatistics() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final questionsSnap = await _firestore.collection('questions').get();
      
      int couples = 0;
      int admins = 0;
      Set<String> countedPartners = {};
      
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        if (data['role'] == 'admin') admins++;
        
        final partnerId = data['partnerId'] as String?;
        if (partnerId != null && partnerId.isNotEmpty) {
          if (!countedPartners.contains(doc.id) && !countedPartners.contains(partnerId)) {
            couples++;
            countedPartners.add(doc.id);
            countedPartners.add(partnerId);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _totalUsers = usersSnap.docs.length;
          _totalCouples = couples;
          _totalQuestions = questionsSnap.docs.length;
          _totalAdmins = admins;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Stats load error: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      
      final users = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      
      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Users load error: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadCouples() async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('partnerId', isNull: false)
          .get();
      
      Map<String, UserModel> userMap = {};
      for (var doc in snap.docs) {
        userMap[doc.id] = UserModel.fromFirestore(doc);
      }
      
      List<Map<String, UserModel>> couplesList = [];
      Set<String> processed = {};
      
      for (var user in userMap.values) {
        if (user.partnerId != null && 
            !processed.contains(user.id) && 
            userMap.containsKey(user.partnerId)) {
          couplesList.add({
            'user1': user,
            'user2': userMap[user.partnerId]!,
          });
          processed.add(user.id);
          processed.add(user.partnerId!);
        }
      }
      
      if (mounted) {
        setState(() {
          _couples = couplesList;
          _isLoadingCouples = false;
        });
      }
    } catch (e) {
      debugPrint('Couples load error: $e');
      if (mounted) setState(() => _isLoadingCouples = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = query.isEmpty ||
            user.displayName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
        final matchesRole = _roleFilter == 'all' || user.role == _roleFilter;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    try {
      await _firestore.collection('users').doc(user.id).update({'role': newRole});
      _showSnack('${user.displayName} role updated: $newRole'); // TODO: Localize parameter
      _loadUsers();
      _loadStatistics();
    } catch (e) {
      _showSnack('${AppStrings.error}: $e', isError: true);
    }
  }

  Future<void> _unlinkCouple(UserModel user1, UserModel user2) async {
      final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.unlinkCouple),
        content: Text('${user1.displayName} ${AppStrings.unlinkConfirm} ${user2.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppStrings.remove),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final batch = _firestore.batch();
        batch.update(_firestore.collection('users').doc(user1.id), {
          'partnerId': null,
          'partnerEmail': null,
        });
        batch.update(_firestore.collection('users').doc(user2.id), {
          'partnerId': null,
          'partnerEmail': null,
        });
        await batch.commit();
        
        _showSnack(AppStrings.partnerUnlinked);
        _loadCouples();
        _loadStatistics();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildUsersTab(),
                    _buildCouplesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.adminPanelTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(
                  height: 20,
                  child: ScrollingText(
                    text: AppStrings.sysManagement,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    velocity: 30,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true, // Allow scrolling if screen is narrow
        tabAlignment: TabAlignment.center, // Center tabs
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16), // Proper padding
        tabs: [
          Tab(
            height: 40, // Reduced height slightly
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_rounded, size: 16),
                SizedBox(width: 4),
                Text(AppStrings.dashboard),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded, size: 16),
                SizedBox(width: 4),
                Text(AppStrings.users),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 16),
                SizedBox(width: 4),
                Text(AppStrings.couples),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DASHBOARD TAB ====================
  Widget _buildDashboardTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.overview,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1, // Adjusted to prevent bottom overflow
            children: [
              _buildStatCard(
                icon: Icons.people,
                title: AppStrings.totalUsers,
                value: _totalUsers.toString(),
                color: Colors.blue,
                gradient: [Colors.blue.shade400, Colors.blue.shade700],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
              ),
              _buildStatCard(
                icon: Icons.favorite,
                title: AppStrings.matchedCouples,
                value: _totalCouples.toString(),
                color: Colors.pink,
                gradient: [Colors.pink.shade400, Colors.pink.shade700],
                onTap: () => _tabController.animateTo(2), // Çiftler tab'ına git
              ),
              _buildStatCard(
                icon: Icons.quiz,
                title: AppStrings.totalQuestions,
                value: _totalQuestions.toString(),
                color: Colors.purple,
                gradient: [Colors.purple.shade400, Colors.purple.shade700],
              ),
              _buildStatCard(
                icon: Icons.admin_panel_settings,
                title: AppStrings.adminCount,
                value: _totalAdmins.toString(),
                color: Colors.orange,
                gradient: [Colors.orange.shade400, Colors.orange.shade700],
              ),
              _buildStatCard(
                icon: Icons.tune,
                title: AppStrings.quizConfigTitle,
                value: '⚙️',
                color: Colors.teal,
                gradient: [Colors.teal.shade400, Colors.teal.shade700],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizConfigurationScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
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

  // ==================== USERS TAB ====================
  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildUserSearchBar(),
        _buildRoleFilterChips(),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? _buildEmptyState(AppStrings.userNotFound, Icons.people_outline)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (ctx, i) => _buildUserCard(_filteredUsers[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        onChanged: _filterUsers,
        decoration: InputDecoration(
          hintText: AppStrings.searchPlaceholder,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip(AppStrings.filterAll, 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(AppStrings.roleUser, 'user'),
          const SizedBox(width: 8),
          _buildFilterChip(AppStrings.roleAdmin, 'admin'),
          const Spacer(),
          Text(
            '${_filteredUsers.length} kayıt',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _roleFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _roleFilter = value);
        _filterUsers(_searchController.text);
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
      backgroundColor: Colors.white,
      checkmarkColor: AppTheme.primaryColor,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName.isNotEmpty ? user.displayName : AppStrings.labelUnknown,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _buildRoleBadge(user.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user.hasPartner ? Icons.favorite : Icons.person,
                  size: 14,
                  color: user.hasPartner ? Colors.pink : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  user.hasPartner ? AppStrings.statusMatched : AppStrings.statusSingle,
                  style: TextStyle(
                    fontSize: 11,
                    color: user.hasPartner ? Colors.pink : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'make_admin':
                _changeUserRole(user, 'admin');
                break;
              case 'make_editor':
                _changeUserRole(user, 'editor');
                break;
              case 'make_user':
                _changeUserRole(user, 'user');
                break;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_vert, size: 20),
          ),
          itemBuilder: (ctx) => [
            if (user.role != 'admin')
              PopupMenuItem(value: 'make_admin', child: Text(AppStrings.makeAdmin)),
            if (user.role != 'editor')
              PopupMenuItem(value: 'make_editor', child: Text(AppStrings.makeEditor)),
            if (user.role != 'user')
              PopupMenuItem(value: 'make_user', child: Text(AppStrings.removeRole)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (role) {
      case 'admin':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = AppStrings.roleAdmin;
        break;
      case 'editor':
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        label = AppStrings.roleEditor;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = AppStrings.roleUser;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ==================== COUPLES TAB ====================
  Widget _buildCouplesTab() {
    if (_isLoadingCouples) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_couples.isEmpty) {
      return _buildEmptyState('Henüz eşleşmiş çift yok', Icons.favorite_outline);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _couples.length,
      itemBuilder: (ctx, i) => _buildCoupleCard(_couples[i]),
    );
  }

  Widget _buildCoupleCard(Map<String, UserModel> couple) {
    final user1 = couple['user1']!;
    final user2 = couple['user2']!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade50,
            Colors.white,
            Colors.red.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildPartnerInfo(user1)),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, color: Colors.pink.shade400, size: 24),
                ),
                Expanded(child: _buildPartnerInfo(user2)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _unlinkCouple(user1, user2),
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Eşleşmeyi Kaldır'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerInfo(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.pink.shade100,
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          user.displayName.isNotEmpty ? user.displayName : 'İsimsiz',
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user.email,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
