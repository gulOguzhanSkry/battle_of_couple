import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/question_model.dart';
import '../../models/quiz_category.dart';
import '../../core/constants/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';

import 'question_detail_screen.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Pagination State
  final int _batchSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<QuestionModel> _questions = [];
  int _totalQuestionCount = 0; // Veritabanındaki toplam soru sayısı
  
  // Filters
  String? _selectedCategoryId;
  String? _selectedDifficulty;
  
  // Selection Mode
  bool _isSelectionMode = false;
  Set<String> _selectedQuestionIds = {};
  
  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
    _loadQuestions();
  }

  Future<void> _loadTotalCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userService = UserService();
      final userModel = await userService.getUserProfile(user.uid);
      
      Query query = _firestore.collection('questions');
      
      // Admin ve Editörler tüm soruları görür, diğerleri sadece kendininkini
      if (userModel == null || !userModel.hasElevatedAccess) {
        query = query.where('createdBy', isEqualTo: user.uid);
      }
      
      final countQuery = await query.count().get();
      
      if (mounted) {
        setState(() => _totalQuestionCount = countQuery.count ?? 0);
      }
    } catch (e) {
      debugPrint('Toplam soru sayısı alınamadı: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _questions = [];
        _lastDocument = null;
        _hasMore = true;
      });
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final userService = UserService();
      final userModel = await userService.getUserProfile(user.uid);

      if (userModel == null) throw Exception('Kullanıcı profili alınamadı');

      Query query = _firestore.collection('questions');
      
      // Admin ve Editörler tüm soruları görür, diğerleri sadece kendininkini
      if (!userModel.hasElevatedAccess) {
        query = query.where('createdBy', isEqualTo: user.uid);
      }
      
      query = query.orderBy('createdAt', descending: true)
          .limit(_batchSize);

      if (_selectedCategoryId != null) {
        query = query.where('categoryId', isEqualTo: _selectedCategoryId);
      }
      
      if (_selectedDifficulty != null) {
        query = query.where('difficulty', isEqualTo: _selectedDifficulty);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        final newQuestions = snapshot.docs
            .map((doc) => QuestionModel.fromFirestore(doc))
            .toList();
        
        setState(() {
          _questions.addAll(newQuestions);
          _lastDocument = snapshot.docs.last;
          if (snapshot.docs.length < _batchSize) _hasMore = false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      if (mounted) _showSnack('${AppStrings.errorTitle}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<QuestionModel> get _filteredQuestions {
    var list = _questions;
    
    // Difficulty filter is now handled server-side
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((q) => 
        q.questionText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        q.options.any((o) => o.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    return list;
  }

  Future<void> _deleteQuestion(String questionId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('questions').doc(questionId).delete();
      setState(() {
        _questions.removeWhere((q) => q.id == questionId);
      });
      if (mounted) _showSnack(AppStrings.questionDeleted);
    } catch (e) {
      if (mounted) _showSnack('${AppStrings.deleteError}: $e', isError: true);
    }
  }

  Future<void> _deleteSelectedQuestions() async {
    if (_selectedQuestionIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content: Text('${_selectedQuestionIds.length} soruyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = _firestore.batch();
      for (final id in _selectedQuestionIds) {
        batch.delete(_firestore.collection('questions').doc(id));
      }
      await batch.commit();

      setState(() {
        _questions.removeWhere((q) => _selectedQuestionIds.contains(q.id));
        _selectedQuestionIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) _showSnack('${_selectedQuestionIds.length} soru silindi');
    } catch (e) {
      if (mounted) _showSnack('${AppStrings.deleteError}: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundColor, AppTheme.surfaceColor],
          ),
        ),
        child: Column(
          children: [
            // _buildSearchAndFilters(), // Moved to AppBar
            _buildStatsBar(),
            Expanded(child: _buildQuestionList()),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode && _selectedQuestionIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _deleteSelectedQuestions,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete),
              label: Text('${_selectedQuestionIds.length} Sil'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isSelectionMode 
          ? '${_selectedQuestionIds.length} seçili' 
          : AppStrings.questionBankTitle),
      backgroundColor: _isSelectionMode ? null : AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedQuestionIds.clear();
              }),
            )
          : null,
      actions: [
        if (_isSelectionMode)
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedQuestionIds.length == _filteredQuestions.length) {
                  _selectedQuestionIds.clear();
                } else {
                  _selectedQuestionIds = _filteredQuestions.map((q) => q.id).toSet();
                }
              });
            },
            child: Text(
              _selectedQuestionIds.length == _filteredQuestions.length ? 'Temizle' : 'Tümünü Seç',
              style: const TextStyle(color: Colors.white),
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => setState(() => _isSelectionMode = true),
            tooltip: 'Seçim Modu',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuestions(refresh: true),
            tooltip: 'Yenile',
          ),
        ],
      ],
      bottom: _isSelectionMode ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Soru ara...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildAppBarFilterButton(
                icon: Icons.category,
                isActive: _selectedCategoryId != null,
                onTap: _showCategoryFilter,
              ),
              const SizedBox(width: 8),
              _buildAppBarFilterButton(
                icon: Icons.speed,
                isActive: _selectedDifficulty != null,
                onTap: _showDifficultyFilter,
              ),
              if (_selectedCategoryId != null || _selectedDifficulty != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                     setState(() {
                        _selectedCategoryId = null;
                        _selectedDifficulty = null;
                      });
                      _loadQuestions(refresh: true);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.filter_list_off, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarFilterButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
        ),
        child: Icon(
          icon, 
          color: isActive ? AppTheme.primaryColor : Colors.white, 
          size: 20,
        ),
      ),
    );
  }



  Widget _buildStatsBar() {
    final loaded = _questions.length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(Icons.storage, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'Toplam: $_totalQuestionCount',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Icon(Icons.download_done, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'Yüklenen: $loaded',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
          ),
          if (_selectedQuestionIds.isNotEmpty) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedQuestionIds.length} Seçili',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    if (_filteredQuestions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Arama sonucu bulunamadı'
                  : AppStrings.noQuestionsYet,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuestions(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _filteredQuestions.length + (_hasMore && _searchQuery.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more button
          if (index == _filteredQuestions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _loadQuestions(),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Yükleniyor...' : AppStrings.loadMore),
                ),
              ),
            );
          }

          final q = _filteredQuestions[index];
          final isSelected = _selectedQuestionIds.contains(q.id);
          
          return _buildQuestionCard(q, index, isSelected);
        },
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, int index, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isSelectionMode
            ? () => _toggleSelection(q.id)
            : () => _showQuestionDetailSheet(q),
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedQuestionIds.add(q.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(q.id),
                      activeColor: AppTheme.primaryColor,
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(q.categoryId).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            q.categoryId,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(q.categoryId),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(q.difficulty).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getDifficultyLabel(q.difficulty),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getDifficultyColor(q.difficulty),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Media indicators
                        if (q.hasImage)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.image, size: 16, color: Colors.blue),
                          ),
                        if (q.hasAudio)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.audiotrack, size: 16, color: Colors.purple),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Question Text
              Text(
                q.questionText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              // Kategori yolu (SubCategory > Topic) varsa göster
              if (q.hasSubCategory || q.hasTopic) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          if (q.hasSubCategory) q.subCategory,
                          if (q.hasTopic) q.topic,
                        ].whereType<String>().join(' > '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Options
              ...q.options.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                final isCorrect = i == q.correctOptionIndex;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect 
                        ? Border.all(color: Colors.green.shade300, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          ['A', 'B', 'C', 'D'][i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorrect ? Colors.green.shade700 : Colors.black87,
                            fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    ],
                  ),
                );
              }),
              // Explanation if exists
              if (q.hasExplanation) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.explanation!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedQuestionIds.contains(id)) {
        _selectedQuestionIds.remove(id);
        if (_selectedQuestionIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedQuestionIds.add(id);
      }
    });
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tüm Kategoriler'),
              selected: _selectedCategoryId == null,
              onTap: () {
                setState(() => _selectedCategoryId = null);
                Navigator.pop(context);
                _loadQuestions(refresh: true);
              },
            ),
            ...QuizCategory.availableCategories.map((c) => ListTile(
              leading: Icon(c.icon),
              title: Text(c.title),
              selected: _selectedCategoryId == c.id,
              onTap: () {
                setState(() => _selectedCategoryId = c.id);
                Navigator.pop(context);
                _loadQuestions(refresh: true);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDifficultyFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zorluk Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Tüm Zorluklar'),
              selected: _selectedDifficulty == null,
              onTap: () {
                setState(() => _selectedDifficulty = null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sentiment_satisfied, color: Colors.green.shade600),
              title: const Text('Kolay'),
              selected: _selectedDifficulty == 'easy',
              onTap: () {
                setState(() => _selectedDifficulty = 'easy');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sentiment_neutral, color: Colors.orange.shade600),
              title: const Text('Orta'),
              selected: _selectedDifficulty == 'medium',
              onTap: () {
                setState(() => _selectedDifficulty = 'medium');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sentiment_very_dissatisfied, color: Colors.red.shade600),
              title: const Text('Zor'),
              selected: _selectedDifficulty == 'hard',
              onTap: () {
                setState(() => _selectedDifficulty = 'hard');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDetailSheet(QuestionModel q) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionDetailScreen(
          question: q,
          onEdit: () {
            // Edit dialog still works as before
            _showEditQuestionDialog(q);
          },
          onDelete: () async {
            // Back to list, then delete
            Navigator.pop(context); 
            await _deleteQuestion(q.id, _questions.indexOf(q));
          },
        ),
      ),
    );
  }

  void _showEditQuestionDialog(QuestionModel q) {
    final questionController = TextEditingController(text: q.questionText);
    final optionControllers = q.options.map((o) => TextEditingController(text: o)).toList();
    final subCategoryController = TextEditingController(text: q.subCategory ?? '');
    final topicController = TextEditingController(text: q.topic ?? '');
    final explanationController = TextEditingController(text: q.explanation ?? '');
    final imageUrlController = TextEditingController(text: q.imageUrl ?? '');
    final audioUrlController = TextEditingController(text: q.audioUrl ?? '');
    int correctIndex = q.correctOptionIndex;
    String difficulty = q.difficulty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Soruyu Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Soru Metni',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Alt Kategori (Opsiyonel)',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Tarih, Biyoloji',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(
                    labelText: 'Konu Başlığı (Opsiyonel)',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Osmanlı Kuruluş Dönemi',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: const InputDecoration(
                    labelText: 'Zorluk',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                    DropdownMenuItem(value: 'medium', child: Text('Orta')),
                    DropdownMenuItem(value: 'hard', child: Text('Zor')),
                  ],
                  onChanged: (val) => setDialogState(() => difficulty = val!),
                ),
                const SizedBox(height: 16),
                const Text('Şıklar:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: correctIndex,
                        onChanged: (val) => setDialogState(() => correctIndex = val!),
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: '${['A', 'B', 'C', 'D'][i]} şıkkı',
                            filled: i == correctIndex,
                            fillColor: Colors.green.shade50,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL (Opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Ses URL (Opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedQuestion = q.copyWith(
                    questionText: questionController.text.trim(),
                    options: optionControllers.map((c) => c.text.trim()).toList(),
                    correctOptionIndex: correctIndex,
                    difficulty: difficulty,
                    subCategory: subCategoryController.text.trim().isEmpty ? null : subCategoryController.text.trim(),
                    topic: topicController.text.trim().isEmpty ? null : topicController.text.trim(),
                    explanation: explanationController.text.trim().isEmpty ? null : explanationController.text.trim(),
                    imageUrl: imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                    audioUrl: audioUrlController.text.trim().isEmpty ? null : audioUrlController.text.trim(),
                  );

                  await _firestore
                      .collection('questions')
                      .doc(q.id)
                      .update(updatedQuestion.toFirestore());

                  setState(() {
                    final index = _questions.indexWhere((x) => x.id == q.id);
                    if (index != -1) _questions[index] = updatedQuestion;
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    _showSnack('Soru güncellendi');
                  }
                } catch (e) {
                  _showSnack('Güncelleme hatası: $e', isError: true);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy': return 'Kolay';
      case 'medium': return 'Orta';
      case 'hard': return 'Zor';
      default: return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getCategoryColor(String categoryId) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[categoryId.hashCode.abs() % colors.length];
  }
}
