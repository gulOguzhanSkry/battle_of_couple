import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/question_model.dart';
import '../../models/quiz_category.dart';
import '../../theme/app_theme.dart';
import '../../services/ai/ai_services.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/ai_prompt_templates.dart';

class AdminQuestionCreatorScreen extends StatefulWidget {
  const AdminQuestionCreatorScreen({super.key});

  @override
  State<AdminQuestionCreatorScreen> createState() => _AdminQuestionCreatorScreenState();
}

class _AdminQuestionCreatorScreenState extends State<AdminQuestionCreatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _manualFormKey = GlobalKey<FormState>();
  
  // Manual Input Controllers
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  
  // Optional Media Controllers (Manuel soru için)
  final _imageUrlController = TextEditingController();
  final _audioUrlController = TextEditingController();
  
  // Optional Content Controllers (Manuel soru için)
  final _manualSubCategoryController = TextEditingController();
  final _manualTopicController = TextEditingController();
  final _manualExplanationController = TextEditingController();
  
  // AI Input Controllers
  final _subCategoryController = TextEditingController();
  final _topicController = TextEditingController();
  double _questionCount = 5;
  bool _includeExplanation = true; // AI açıklama üretsin mi?

  // Shared State
  QuizCategory? _selectedCategory;
  int _correctOptionIndex = 0;
  String _difficulty = 'medium';
  String? _selectedStyle; // New variable for PDR style
  bool _isLoading = false;
  
  // AI Generated Questions List
  List<QuestionModel> _generatedQuestions = [];
  Set<int> _selectedQuestionIndices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _subCategoryController.dispose();
    _topicController.dispose();
    _imageUrlController.dispose();
    _audioUrlController.dispose();
    _manualSubCategoryController.dispose();
    _manualTopicController.dispose();
    _manualExplanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- MANUAL SAVING ---
  Future<void> _saveManualQuestion() async {
    if (!_manualFormKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack(AppStrings.selectCategory, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(AppStrings.sessionNotFound);

      final questionId = const Uuid().v4();
      final options = _optionControllers.map((c) => c.text.trim()).toList();

      final question = QuestionModel(
        id: questionId,
        questionText: _questionController.text.trim(),
        options: options,
        correctOptionIndex: _correctOptionIndex,
        categoryId: _selectedCategory!.id,
        difficulty: _difficulty,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        // Opsiyonel kategori alanları
        subCategory: _manualSubCategoryController.text.trim().isEmpty ? null : _manualSubCategoryController.text.trim(),
        topic: _manualTopicController.text.trim().isEmpty ? null : _manualTopicController.text.trim(),
        // Opsiyonel içerik alanları
        explanation: _manualExplanationController.text.trim().isEmpty ? null : _manualExplanationController.text.trim(),
        // Opsiyonel medya alanları
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        audioUrl: _audioUrlController.text.trim().isEmpty ? null : _audioUrlController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .set(question.toFirestore());

      if (mounted) {
        _showSnack(AppStrings.questionSaved);
        _resetManualForm();
      }
    } catch (e) {
      if (mounted) _showSnack('${AppStrings.errorTitle}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- AI GENERATION ---
  Future<void> _generateAIQuestions() async {
    if (_selectedCategory == null) {
      _showSnack(AppStrings.selectCategory, isError: true);
      return;
    }
    // subCategory artık opsiyonel, validation kaldırıldı

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(AppStrings.sessionNotFound);

      // OpenAI (ChatGPT) servisini kullan
      final aiService = AIServiceFactory.getService(AIProvider.openai);
      if (!aiService.isConfigured) {
        throw AIServiceException(
          provider: 'OpenAI',
          message: 'OpenAI API Key bulunamadı. .env dosyasında OPENAI_API_KEY tanımlayın.',
        );
      }

      final questions = await aiService.generateQuestions(
        categoryId: _selectedCategory!.title,
        subCategory: _subCategoryController.text.isEmpty ? null : _subCategoryController.text,
        topic: _topicController.text.isEmpty ? null : _topicController.text,
        difficulty: _difficulty,
        count: _questionCount.toInt(),
        userId: user.uid,
        style: _selectedStyle,
      );

      setState(() {
        _generatedQuestions = questions;
        _selectedQuestionIndices = {}; // Reset selection
      });

    } catch (e) {
      if (mounted) _showSnack('${AppStrings.aiError}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPromptPreview() {
    if (_selectedCategory == null) {
      _showSnack(AppStrings.selectCategory, isError: true);
      return;
    }

    final promptBuilder = PromptBuilderFactory.getBuilder(_selectedCategory!.id);
    final prompt = promptBuilder.buildPrompt(
      subCategory: _subCategoryController.text.isEmpty ? null : _subCategoryController.text,
      topic: _topicController.text.isEmpty ? null : _topicController.text,
      difficulty: _difficulty,
      count: _questionCount.toInt(),
      style: _selectedStyle,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Prompt Önizleme'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bu prompt AI servisine gönderilecek:',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  prompt,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAIQuestions();
            },
            child: const Text('Onayla ve Üret'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelectedAIQuestions() async {
    if (_selectedQuestionIndices.isEmpty) {
      _showSnack(AppStrings.selectQuestions, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('questions');

      for (var index in _selectedQuestionIndices) {
        final originalQ = _generatedQuestions[index];
        final docRef = collection.doc(); // Auto ID
        
        // Clone with correct ID and CategoryID (opsiyonel alanları koru)
        final questionToSave = QuestionModel(
          id: docRef.id,
          questionText: originalQ.questionText,
          options: originalQ.options,
          correctOptionIndex: originalQ.correctOptionIndex,
          categoryId: _selectedCategory!.id,
          difficulty: _difficulty,
          createdAt: DateTime.now(),
          createdBy: originalQ.createdBy,
          // AI tarafından üretilen opsiyonel alanları koru
          subCategory: originalQ.subCategory,
          topic: originalQ.topic,
          // Açıklama toggle'ına göre explanation ekle veya null bırak
          explanation: _includeExplanation ? originalQ.explanation : null,
        );

        batch.set(docRef, questionToSave.toFirestore());
      }

      await batch.commit();

      if (mounted) {
        _showSnack('${_selectedQuestionIndices.length} ${AppStrings.questionsSavedToDb}');
        setState(() {
          _generatedQuestions.clear();
          _selectedQuestionIndices.clear();
        });
      }
    } catch (e) {
      if (mounted) _showSnack('${AppStrings.saveError}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetManualForm() {
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    _imageUrlController.clear();
    _audioUrlController.clear();
    _manualSubCategoryController.clear();
    _manualTopicController.clear();
    _manualExplanationController.clear();
    setState(() => _correctOptionIndex = 0);
  }

  void _showSnack(String message, {bool isError = false}) {
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
      appBar: AppBar(
        title: Text(AppStrings.adminTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: AppStrings.tabManual),
            Tab(text: AppStrings.tabAI),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundColor, AppTheme.surfaceColor],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildManualTab(),
            _buildAITab(),
          ],
        ),
      ),
    );
  }

  // ... MANUAL UI ...
  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _manualFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildDifficultyDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _questionController,
              label: AppStrings.labelQuestionText,
              maxLines: 3,
              icon: Icons.help_outline,
            ),
            const SizedBox(height: 24),
            const Text(
              'Şıklar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (index) => _buildOptionField(index)),
            const SizedBox(height: 16),
            // Opsiyonel Medya Alanları
            _buildOptionalMediaSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveManualQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(AppStrings.btnSaveManual, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ... AI UI ...
  Widget _buildAITab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                if (_selectedCategory?.id == 'PDR') ...[
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Soru Tarzı (PDR Özel)',
                      prefixIcon: const Icon(Icons.style),
                    ),
                    value: _selectedStyle,
                    items: [
                      DropdownMenuItem(value: null, child: const Text('Karışık (Varsayılan)')),
                      DropdownMenuItem(value: 'vaka', child: const Text('Vaka Analizi')),
                      DropdownMenuItem(value: 'durumsal', child: const Text('Durumsal/Uygulama')),
                      DropdownMenuItem(value: 'karsilastirma', child: const Text('Kavram Karşılaştırma')),
                      DropdownMenuItem(value: 'kavram', child: const Text('Kavramsal Bilgi')),
                    ],
                    onChanged: (value) => setState(() => _selectedStyle = value),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  controller: _subCategoryController,
                  label: AppStrings.labelSubCategory,
                  icon: Icons.subdirectory_arrow_right,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _topicController,
                  label: AppStrings.labelTopic,
                  icon: Icons.topic,
                  required: false,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDifficultyDropdown()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${AppStrings.labelQuestionCount}: ${_questionCount.toInt()}'),
                          Slider(
                            value: _questionCount,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) => setState(() => _questionCount = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Açıklama toggle
                Card(
                  elevation: 0,
                  color: AppTheme.surfaceColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    value: _includeExplanation,
                    onChanged: (val) => setState(() => _includeExplanation = val),
                    title: const Text('Açıklama Ekle'),
                    subtitle: Text(
                      _includeExplanation 
                          ? 'AI her soru için açıklama üretecek'
                          : 'Sadece soru ve şıklar üretilecek',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    secondary: Icon(
                      Icons.lightbulb_outline,
                      color: _includeExplanation ? Colors.amber : Colors.grey,
                    ),
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateAIQuestions,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? AppStrings.generating : AppStrings.btnGenerateAI),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showPromptPreview,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Prompt Önizle'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 24),
                if (_generatedQuestions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppStrings.preview} (${_generatedQuestions.length} ${AppStrings.labelQuestionCount})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                             if (_selectedQuestionIndices.length == _generatedQuestions.length) {
                               _selectedQuestionIndices.clear();
                             } else {
                               _selectedQuestionIndices = Set.from(
                                 List.generate(_generatedQuestions.length, (i) => i)
                               );
                             }
                          });
                        },
                        child: Text(_selectedQuestionIndices.length == _generatedQuestions.length 
                          ? AppStrings.clear 
                          : AppStrings.selectAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_generatedQuestions.length, (index) {
                    final q = _generatedQuestions[index];
                    final isSelected = _selectedQuestionIndices.contains(index);
                    return Card(
                      color: isSelected ? Colors.green.shade50 : null,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.grey.shade300,
                          width: 2
                        ),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedQuestionIndices.remove(index);
                            } else {
                              _selectedQuestionIndices.add(index);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${q.questionText}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...q.options.asMap().entries.map((e) => Text(
                                '${['A','B','C','D'][e.key]}) ${e.value}',
                                style: TextStyle(
                                  color: e.key == q.correctOptionIndex ? Colors.green : Colors.black87,
                                  fontWeight: e.key == q.correctOptionIndex ? FontWeight.bold : FontWeight.normal,
                                )
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        if (_generatedQuestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelectedAIQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                '${AppStrings.btnSaveSelected} (${_selectedQuestionIndices.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<QuizCategory>(
      decoration: InputDecoration(labelText: AppStrings.labelCategory, prefixIcon: Icon(Icons.category)),
      value: _selectedCategory,
      items: QuizCategory.availableCategories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category.title));
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      validator: (value) => value == null ? AppStrings.selectCategory : null,
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: AppStrings.labelDifficulty, prefixIcon: Icon(Icons.speed)),
      value: _difficulty,
      items: [
        DropdownMenuItem(value: 'easy', child: Text(AppStrings.diffEasy)),
        DropdownMenuItem(value: 'medium', child: Text(AppStrings.diffMedium)),
        DropdownMenuItem(value: 'hard', child: Text(AppStrings.diffHard)),
      ],
      onChanged: (value) => setState(() => _difficulty = value!),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), alignLabelWithHint: maxLines > 1),
      maxLines: maxLines,
      validator: required ? (value) => value!.isEmpty ? AppStrings.requiredField : null : null,
    );
  }

  Widget _buildOptionField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: _correctOptionIndex,
            onChanged: (value) => setState(() => _correctOptionIndex = value!),
            activeColor: Colors.green,
          ),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                labelText: '${['A','B','C','D'][index]} ${AppStrings.optionC}',
                filled: true,
                fillColor: index == _correctOptionIndex ? Colors.green.withOpacity(0.1) : AppTheme.surfaceColor,
              ),
              validator: (value) => value!.isEmpty ? AppStrings.enterOption : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Opsiyonel alanlar için ExpansionTile widget'ı (Kategori + İçerik + Medya)
  Widget _buildOptionalMediaSection() {
    final hasContent = _manualSubCategoryController.text.isNotEmpty ||
                       _manualTopicController.text.isNotEmpty ||
                       _manualExplanationController.text.isNotEmpty ||
                       _imageUrlController.text.isNotEmpty || 
                       _audioUrlController.text.isNotEmpty;
    
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.tune, color: Colors.grey),
        title: const Text(
          'Opsiyonel Alanlar',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          hasContent 
              ? 'İçerik eklendi' 
              : 'Alt kategori, konu, açıklama ekleyin',
          style: TextStyle(
            fontSize: 12,
            color: hasContent ? Colors.green : Colors.grey,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Alt Kategori
                TextFormField(
                  controller: _manualSubCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Alt Kategori (Opsiyonel)',
                    hintText: 'Örn: Tarih, Biyoloji, Matematik',
                    prefixIcon: Icon(Icons.subdirectory_arrow_right),
                    helperText: 'Ana kategorinin alt dalı',
                  ),
                ),
                const SizedBox(height: 16),
                // Konu Başlığı
                TextFormField(
                  controller: _manualTopicController,
                  decoration: const InputDecoration(
                    labelText: 'Konu Başlığı (Opsiyonel)',
                    hintText: 'Örn: Osmanlı Kuruluş Dönemi',
                    prefixIcon: Icon(Icons.topic),
                    helperText: 'Sorunun ait olduğu spesifik konu',
                  ),
                ),
                const SizedBox(height: 16),
                // Açıklama
                TextFormField(
                  controller: _manualExplanationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Cevap Açıklaması (Opsiyonel)',
                    hintText: 'Doğru cevabın neden doğru olduğunu açıklayın',
                    prefixIcon: Icon(Icons.lightbulb_outline),
                    helperText: 'Kullanıcıya gösterilecek açıklama',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Görsel URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL (Opsiyonel)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.image),
                    helperText: 'Firebase Storage veya harici görsel URL\'i',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                // Ses URL
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Ses Dosyası URL (Opsiyonel)',
                    hintText: 'https://example.com/audio.mp3',
                    prefixIcon: Icon(Icons.audiotrack),
                    helperText: 'Gelecek için altyapı - Ses sorularında kullanılacak',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
