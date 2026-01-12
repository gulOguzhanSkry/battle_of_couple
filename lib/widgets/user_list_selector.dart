import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

/// Reusable widget for listing and selecting users
class UserListSelector extends StatefulWidget {
  final Function(UserModel)? onUserSelected;
  final bool selectionMode;
  final ScrollController? parentScrollController;

  const UserListSelector({
    super.key,
    this.onUserSelected,
    this.selectionMode = false,
    this.parentScrollController,
  });

  @override
  State<UserListSelector> createState() => _UserListSelectorState();
}

class _UserListSelectorState extends State<UserListSelector> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _internalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Pagination
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<UserModel> _users = [];
  
  // Filters
  String _roleFilter = 'all'; 
  String _searchQuery = '';

  ScrollController get _scrollController => widget.parentScrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.parentScrollController == null) {
      _internalScrollController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients && 
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      setState(() {
        _users = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }
    
    setState(() => _isLoading = true);
    
    try {
      Query query = _firestore.collection('users').orderBy('createdAt', descending: true);
      
      if (_roleFilter != 'all') {
        query = query.where('role', isEqualTo: _roleFilter);
      }
      
      query = query.limit(_pageSize);
      
      final snap = await query.get();
      
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        final newUsers = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
        
        setState(() {
          _users = _applyLocalFilters(newUsers);
          _hasMore = snap.docs.length == _pageSize;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      Query query = _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);
      
      if (_roleFilter != 'all') {
        query = query.where('role', isEqualTo: _roleFilter);
      }
      
      final snap = await query.get();
      
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        final newUsers = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
        
        setState(() {
          _users.addAll(_applyLocalFilters(newUsers));
          _hasMore = snap.docs.length == _pageSize;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserModel> _applyLocalFilters(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() => _searchQuery = val);
          _loadUsers(refresh: true);
        },
        decoration: InputDecoration(
          hintText: 'Kullanıcı Ara (İsim/Email)...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadUsers(refresh: true);
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Tümü', 'all', _roleFilter, (v) {
            setState(() => _roleFilter = v);
            _loadUsers(refresh: true);
          }),
          _buildFilterChip('Kullanıcı', 'user', _roleFilter, (v) {
            setState(() => _roleFilter = v);
            _loadUsers(refresh: true);
          }),
          _buildFilterChip('Admin', 'admin', _roleFilter, (v) {
            setState(() => _roleFilter = v);
            _loadUsers(refresh: true);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, Function(String) onSelected) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label, 
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
        backgroundColor: AppTheme.surfaceColor,
        checkmarkColor: AppTheme.primaryColor,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_users.isEmpty) {
      return Center(
        child: Text('Kullanıcı bulunamadı.', style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + (_hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _users.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        return _buildUserCard(_users[i]);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => widget.onUserSelected?.call(user),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(user.displayName.isNotEmpty ? user.displayName : 'Bilinmeyen'),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: widget.selectionMode 
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
}
