import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'admin/admin_question_creator_screen.dart';
import 'admin/question_bank_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_rewards_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import 'admin/quiz_configuration_screen.dart';

class DeveloperOptionsScreen extends StatefulWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  State<DeveloperOptionsScreen> createState() => _DeveloperOptionsScreenState();
}

class _DeveloperOptionsScreenState extends State<DeveloperOptionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _uploadStatus = '';
  
  // Kullanıcı rolü
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _currentUser = UserModel.fromFirestore(doc);
            _isLoadingUser = false;
          });
        }
      } catch (e) {
        debugPrint('User load error: $e');
        if (mounted) setState(() => _isLoadingUser = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _resetMyPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({'points': 0});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.debugPointsReset)));
    }
  }

  Future<void> _addFakePoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({'points': FieldValue.increment(100)});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.debugPointsAdded)));
    }
  }

  Future<void> _uploadDictionary() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = AppStrings.debugReadingFile;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/oxford_3000.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      setState(() => _uploadStatus = '${jsonList.length} ${AppStrings.debugUploadStart}');

      final batchSize = 500;
      var batch = _firestore.batch();
      var count = 0;
      var totalUploaded = 0;

      for (var item in jsonList) {
        final docRef = _firestore.collection('words').doc();
        
        batch.set(docRef, {
          'en': item['en'],
          'tr': item['tr'],
          'level': 'A1-B2',
          'source': 'oxford_3000',
          'createdAt': FieldValue.serverTimestamp(),
        });

        count++;
        
        if (count >= batchSize) {
           await batch.commit();
           totalUploaded += count;
           setState(() => _uploadStatus = '$totalUploaded / ${jsonList.length} ${AppStrings.debugUploading}');
           batch = _firestore.batch();
           count = 0;
           await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (count > 0) {
        await batch.commit();
        totalUploaded += count;
      }

      setState(() => _uploadStatus = '${AppStrings.debugUploadComplete} $totalUploaded ${AppStrings.debugWordsUploaded}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.debugUploadSuccess)));

    } catch (e) {
      setState(() => _uploadStatus = '${AppStrings.error}: $e');
      debugPrint('Sözlük yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.devPanel),
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = _currentUser?.isAdmin ?? false;
    final isEditor = _currentUser?.isEditor ?? false;
    final canManageContent = isAdmin || isEditor;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.devPanel),
        backgroundColor: isAdmin ? Colors.red.shade900 : Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rol göstergesi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.red.shade50 : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAdmin ? Colors.red.shade200 : Colors.purple.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.edit_note,
                  color: isAdmin ? Colors.red.shade700 : Colors.purple.shade700,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rol: ${_currentUser?.roleDisplayName ?? AppStrings.labelUnknown}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.red.shade700 : Colors.purple.shade700,
                      ),
                    ),
                    Text(
                      isAdmin ? AppStrings.adminPermissions : AppStrings.editorPermissions,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Admin Only: Yönetim Paneli
          if (isAdmin) ...[
            _buildHashtagHeader('# ${AppStrings.adminPanelTitle}'),
            _buildDebugAction(
              icon: Icons.admin_panel_settings,
              title: AppStrings.adminDashboard,
              subtitle: AppStrings.sysManagement,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
            _buildDebugAction(
              icon: Icons.card_giftcard,
              title: 'Hediye Çeki Yönetimi',
              subtitle: 'Ödül şablonları oluştur ve ata',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRewardsScreen()),
                );
              },
            ),
            _buildDebugAction(
              icon: Icons.tune,
              title: AppStrings.quizConfigTitle,
              subtitle: 'Min. başarı oranlarını ayarla',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizConfigurationScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Admin & Editor: İçerik Araçları
          if (canManageContent) ...[
            _buildHashtagHeader(AppStrings.debugContentHeader),
            _buildDebugAction(
              icon: Icons.auto_awesome,
              title: AppStrings.debugQuestWizard,
              subtitle: AppStrings.debugQuestWizardDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminQuestionCreatorScreen()),
                );
              },
            ),
            _buildDebugAction(
              icon: Icons.storage,
              title: AppStrings.debugQuestBank,
              subtitle: AppStrings.debugQuestBankDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Admin Only: Debug Araçları
          if (isAdmin) ...[
            _buildHashtagHeader(AppStrings.debugPlayerHeader),
            _buildDebugAction(
              icon: Icons.exposure_zero,
              title: AppStrings.debugResetPoints,
              subtitle: AppStrings.debugResetPointsDesc,
              onTap: _resetMyPoints,
            ),
            _buildDebugAction(
              icon: Icons.plus_one,
              title: AppStrings.debugAddPoints,
              subtitle: AppStrings.debugAddPointsDesc,
              onTap: _addFakePoints,
            ),
            const SizedBox(height: 20),
            _buildHashtagHeader(AppStrings.debugDataHeader),
            _buildDebugAction(
              icon: Icons.language,
              title: AppStrings.debugLoadDictionary,
              subtitle: _isUploading ? _uploadStatus : AppStrings.debugLoadDictionaryDesc,
              onTap: _isUploading ? () {} : _uploadDictionary,
              isLoading: _isUploading,
            ),
            if (_uploadStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_uploadStatus, style: const TextStyle(color: Colors.blue)),
              ),
            const SizedBox(height: 20),
          ],

          // Sistem Bilgisi (herkes için)
          _buildHashtagHeader(AppStrings.debugSystemHeader),
          ListTile(
            title: Text(AppStrings.debugUserId),
            subtitle: SelectableText(FirebaseAuth.instance.currentUser?.uid ?? AppStrings.none),
            leading: const Icon(Icons.person_outline),
          ),
          ListTile(
            title: Text(AppStrings.debugAppVersion),
            subtitle: const Text('1.0.0 (Build 1)'),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDebugAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: isLoading 
            ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)) 
            : Icon(icon, color: Colors.black87),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
