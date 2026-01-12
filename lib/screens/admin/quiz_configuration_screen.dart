import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../models/quiz_category.dart';
import '../../games/quiz/services/quiz_settings_service.dart';
import '../../theme/app_theme.dart';

class QuizConfigurationScreen extends StatefulWidget {
  const QuizConfigurationScreen({super.key});

  @override
  State<QuizConfigurationScreen> createState() => _QuizConfigurationScreenState();
}

class _QuizConfigurationScreenState extends State<QuizConfigurationScreen> {
  final QuizSettingsService _settingsService = QuizSettingsService();
  final Map<String, int> _successRates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    for (var category in QuizCategory.availableCategories) {
      final rate = await _settingsService.getMinSuccessRate(category.id);
      _successRates[category.id] = rate;
    }
    if (mounted) setState(() => _isLoading = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.quizConfigTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAllSettings,
        tooltip: 'Ayarları Kaydet',
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.save, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: QuizCategory.availableCategories.length,
              itemBuilder: (context, index) {
                final category = QuizCategory.availableCategories[index];
                return _buildCategoryCard(category);
              },
            ),
    );
  }

  Widget _buildCategoryCard(QuizCategory category) {
    final currentRate = _successRates[category.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currentRate%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              AppStrings.minSuccessRate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: currentRate.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: category.color,
                    label: '$currentRate%',
                    onChanged: (value) {
                      setState(() {
                        _successRates[category.id] = value.round();
                      });
                    },
                  ),
                ),
              ],
            ),
            Text(
              currentRate == 0 
                  ? 'Baraj yok (Herkes puan alır)' 
                  : 'Kullanıcılar en az %$currentRate başarı göstermeli',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);
    try {
      final futures = _successRates.entries.map(
        (e) => _settingsService.updateMinSuccessRate(e.key, e.value)
      );
      await Future.wait(futures);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppStrings.saveSuccess), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${AppStrings.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
