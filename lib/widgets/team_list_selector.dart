import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/couple_team.dart';


class TeamListSelector extends StatefulWidget {
  final Function(CoupleTeam)? onTeamSelected;
  final bool selectionMode; // If true, simpler UI for selection

  const TeamListSelector({
    super.key,
    this.onTeamSelected,
    this.selectionMode = false,
  });

  @override
  State<TeamListSelector> createState() => _TeamListSelectorState();
}

class _TeamListSelectorState extends State<TeamListSelector> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<CoupleTeam> _teams = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTeams();
    }
  }

  Future<void> _loadTeams({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      if (mounted) {
        setState(() {
          _teams = [];
          _lastDocument = null;
          _hasMore = true;
        });
      }
    }

    setState(() => _isLoading = true);

    try {
      Query query = _firestore.collection('coupleTeams').orderBy('createdAt', descending: true);
      
      // Basic search filter handled locally or via simple query if exact match needed.
      // Firestore text search is limited. We'll do local filtering for this MVP 
      // as querying by text substring isn't native without 3rd party.
      
      query = query.limit(_pageSize);

      final snap = await query.get();

      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        final newTeams = snap.docs.map((d) => CoupleTeam.fromFirestore(d)).toList();

        setState(() {
          _teams = _applyLocalFilters(newTeams);
          _hasMore = snap.docs.length == _pageSize;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading teams: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreTeams() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoading = true);

    try {
      Query query = _firestore.collection('coupleTeams')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snap = await query.get();

      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        final newTeams = snap.docs.map((d) => CoupleTeam.fromFirestore(d)).toList();

        setState(() {
          _teams.addAll(_applyLocalFilters(newTeams));
          _hasMore = snap.docs.length == _pageSize;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more teams: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CoupleTeam> _applyLocalFilters(List<CoupleTeam> teams) {
    if (_searchQuery.isEmpty) return teams;
    final query = _searchQuery.toLowerCase();
    return teams.where((team) {
      return team.teamName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildTeamList()),
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
          _loadTeams(refresh: true);
        },
        decoration: InputDecoration(
          hintText: 'Takım Ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadTeams(refresh: true);
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

  Widget _buildTeamList() {
    if (_isLoading && _teams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty) {
      return Center(
        child: Text('Takım bulunamadı.', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length + (_hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _teams.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        return _buildTeamCard(_teams[i]);
      },
    );
  }

  Widget _buildTeamCard(CoupleTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => widget.onTeamSelected?.call(team),
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: Text(team.teamEmoji ?? '❤️'),
        ),
        title: Text(team.teamName.isNotEmpty ? team.teamName : 'İsimsiz Takım'),
        subtitle: Text('ID: ${team.id.substring(0, 8)}...', style: const TextStyle(fontSize: 12)),
        trailing: widget.selectionMode
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
}
