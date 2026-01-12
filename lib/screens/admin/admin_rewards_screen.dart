import 'package:flutter/material.dart';
import '../../models/reward_model.dart';
import '../../models/user_model.dart';
import '../../models/couple_team.dart';
import '../../widgets/reward_card.dart';
import '../../widgets/user_list_selector.dart';
import '../../widgets/team_list_selector.dart';
import '../../services/reward_service.dart';
import 'assigned_rewards_screen.dart';

class AdminRewardsScreen extends StatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  State<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends State<AdminRewardsScreen> {
  final RewardService _rewardService = RewardService();
  List<RewardModel>? _templates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final allTemplates = await _rewardService.getTemplates();
      // Filter out already assigned gift certificates
      final availableTemplates = allTemplates.where((t) => !t.isAssigned).toList();
      setState(() {
        _templates = availableTemplates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hediye Çeki Yönetimi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Atama Geçmişi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignedRewardsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTemplateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hediye Çeki'),
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates == null || _templates!.isEmpty
              ? const Center(child: Text('Henüz şablon yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates!.length,
                  itemBuilder: (context, index) {
                    final template = _templates![index];
                    return Dismissible(
                      key: Key(template.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 32),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hediye Çekini Sil'),
                            content: Text('"${template.title}" şablonunu silmek istediğinizden emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          await _rewardService.deleteTemplate(template.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${template.title} silindi.')),
                          );
                          _loadTemplates();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: GestureDetector(
                        onTap: () => _showEditTemplateDialog(template),
                        child: RewardCard(
                          reward: template,
                          isAdmin: true,
                          onAssign: () => _showAssignDialog(template),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showCreateTemplateDialog() async {
    // Get existing titles for suggestions
    final existingTitles = _templates?.map((t) => t.title).toSet().toList() ?? [];
    
    final result = await showModalBottomSheet<RewardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTemplateSheet(
        existingTitles: existingTitles,
      ),
    );
    
    if (result != null) {
      try {
        await _rewardService.createTemplate(result);
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hediye çeki oluşturuldu'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showEditTemplateDialog(RewardModel template) async {
    final existingTitles = _templates?.map((t) => t.title).toSet().toList() ?? [];
    
    final result = await showModalBottomSheet<RewardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTemplateSheet(
        template: template,
        existingTitles: existingTitles,
      ),
    );
    
    if (result != null) {
      try {
        await _rewardService.updateTemplate(result);
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hediye çeki güncellendi'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAssignDialog(RewardModel template) {
    showDialog(
      context: context,
      builder: (context) => AssignmentDialog(
        template: template, 
        rewardService: _rewardService,
      ),
    );
  }
}

class AssignmentDialog extends StatefulWidget {
  final RewardModel template;
  final RewardService rewardService;

  const AssignmentDialog({
    super.key,
    required this.template,
    required this.rewardService,
  });

  @override
  State<AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<AssignmentDialog> {
  // 0 = User, 1 = Team
  int _selectedTab = 0;
  
  // Selection
  UserModel? _selectedUser;
  CoupleTeam? _selectedTeam; // Uses CoupleTeam model
  
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.template.title} Ata'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Tabs
            Row(
              children: [
                Expanded(child: _buildTab('Kullanıcı', 0)),
                Expanded(child: _buildTab('Çift/Takım', 1)),
              ],
            ),
            const Divider(),
            
            // Selector Area
            Expanded(
              child: _selectedTab == 0
                  ? UserListSelector(
                      selectionMode: true,
                      onUserSelected: (u) => setState(() => _selectedUser = u),
                    )
                  : TeamListSelector(
                      selectionMode: true,
                      onTeamSelected: (t) => setState(() => _selectedTeam = t),
                    ),
            ),
            
            const SizedBox(height: 10),
            
            // Selected Item Display
            if (_selectedTab == 0 && _selectedUser != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Seçilen: ${_selectedUser!.displayName}')),
                  ],
                ),
              ),
              
            if (_selectedTab == 1 && _selectedTeam != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.purple.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Seçilen: ${_selectedTeam!.teamName}')),
                  ],
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
          onPressed: _isAssigning || (_selectedTab == 0 ? _selectedUser == null : _selectedTeam == null)
              ? null
              : _handleAssign,
          child: _isAssigning 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ata'),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() {
        _selectedTab = index;
        _selectedUser = null;
        _selectedTeam = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.pink : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.pink : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAssign() async {
    setState(() => _isAssigning = true);
    
    try {
      if (_selectedTab == 0 && _selectedUser != null) {
        await widget.rewardService.assignRewardToUser(
          userId: _selectedUser!.id,
          template: widget.template,
        );
      } else if (_selectedTab == 1 && _selectedTeam != null) {
        final t = _selectedTeam!;
        // Partners are non-nullable in model
        await widget.rewardService.assignRewardToTeam(
          partner1Id: t.partner1Id,
          partner2Id: t.partner2Id,
          template: widget.template,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hediye çeki başarıyla atandı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atama hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }
}

/// Beautiful themed bottom sheet for creating reward templates
class _CreateTemplateSheet extends StatefulWidget {
  final List<String> existingTitles;

  const _CreateTemplateSheet({required this.existingTitles});

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _codeController = TextEditingController();
  final _messageController = TextEditingController();
  final _titleFocusNode = FocusNode();
  
  bool _showTitleSuggestions = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.existingTitles;
    _titleController.addListener(_onTitleChanged);
    _titleFocusNode.addListener(() {
      setState(() => _showTitleSuggestions = _titleFocusNode.hasFocus && _filteredSuggestions.isNotEmpty);
    });
  }

  void _onTitleChanged() {
    final query = _titleController.text.toLowerCase();
    setState(() {
      _filteredSuggestions = widget.existingTitles
          .where((t) => t.toLowerCase().contains(query))
          .toList();
      _showTitleSuggestions = _titleFocusNode.hasFocus && _filteredSuggestions.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _codeController.dispose();
    _messageController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _selectTitle(String title) {
    _titleController.text = title;
    setState(() => _showTitleSuggestions = false);
    _titleFocusNode.unfocus();
  }

  void _submit() {
    if (_titleController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve Kod zorunludur'), backgroundColor: Colors.orange),
      );
      return;
    }

    final template = RewardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: _amountController.text.trim(),
      code: _codeController.text.trim(),
      message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      isScratched: true,
      color: Colors.pink,
      icon: Icons.card_giftcard,
    );

    Navigator.pop(context, template);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni Hediye Çeki',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Yeni hediye çeki ekle',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title field with suggestions
              _buildTextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                label: 'Başlık',
                hint: 'Örn: Trendyol, Hepsiburada...',
                icon: Icons.label_outline,
              ),
              
              // Title suggestions dropdown
              if (_showTitleSuggestions)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (ctx, i) {
                      final title = _filteredSuggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                        title: Text(title, style: const TextStyle(fontSize: 14)),
                        onTap: () => _selectTitle(title),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Amount field
              _buildTextField(
                controller: _amountController,
                label: 'Miktar',
                hint: 'Örn: 100 TL',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),

              // Code field
              _buildTextField(
                controller: _codeController,
                label: 'Hediye Kodu',
                hint: 'Örn: GIFT-2024-XYZ',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 16),

              // Message field
              _buildTextField(
                controller: _messageController,
                label: 'Mesaj (Opsiyonel)',
                hint: 'Kullanıcıya özel mesaj...',
                icon: Icons.message_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Hediye Çeki Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

/// Beautiful themed bottom sheet for editing reward templates
class _EditTemplateSheet extends StatefulWidget {
  final RewardModel template;
  final List<String> existingTitles;

  const _EditTemplateSheet({
    required this.template,
    required this.existingTitles,
  });

  @override
  State<_EditTemplateSheet> createState() => _EditTemplateSheetState();
}

class _EditTemplateSheetState extends State<_EditTemplateSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _codeController;
  late TextEditingController _messageController;
  final _titleFocusNode = FocusNode();
  
  bool _showTitleSuggestions = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template.title);
    _amountController = TextEditingController(text: widget.template.amount);
    _codeController = TextEditingController(text: widget.template.code);
    _messageController = TextEditingController(text: widget.template.message ?? '');
    
    _filteredSuggestions = widget.existingTitles;
    _titleController.addListener(_onTitleChanged);
    _titleFocusNode.addListener(() {
      setState(() => _showTitleSuggestions = _titleFocusNode.hasFocus && _filteredSuggestions.isNotEmpty);
    });
  }

  void _onTitleChanged() {
    final query = _titleController.text.toLowerCase();
    setState(() {
      _filteredSuggestions = widget.existingTitles
          .where((t) => t.toLowerCase().contains(query))
          .toList();
      _showTitleSuggestions = _titleFocusNode.hasFocus && _filteredSuggestions.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _codeController.dispose();
    _messageController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _selectTitle(String title) {
    _titleController.text = title;
    setState(() => _showTitleSuggestions = false);
    _titleFocusNode.unfocus();
  }

  void _submit() {
    if (_titleController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve Kod zorunludur'), backgroundColor: Colors.orange),
      );
      return;
    }

    final updatedTemplate = widget.template.copyWith(
      title: _titleController.text.trim(),
      amount: _amountController.text.trim(),
      code: _codeController.text.trim(),
      message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
    );

    Navigator.pop(context, updatedTemplate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hediye Çekini Düzenle',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.template.title,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title field with suggestions
              _buildTextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                label: 'Başlık',
                hint: 'Örn: Trendyol, Hepsiburada...',
                icon: Icons.label_outline,
              ),
              
              // Title suggestions dropdown
              if (_showTitleSuggestions)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (ctx, i) {
                      final title = _filteredSuggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                        title: Text(title, style: const TextStyle(fontSize: 14)),
                        onTap: () => _selectTitle(title),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Amount field
              _buildTextField(
                controller: _amountController,
                label: 'Miktar',
                hint: 'Örn: 100 TL',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 16),

              // Code field
              _buildTextField(
                controller: _codeController,
                label: 'Hediye Kodu',
                hint: 'Örn: GIFT-2024-XYZ',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 16),

              // Message field
              _buildTextField(
                controller: _messageController,
                label: 'Mesaj (Opsiyonel)',
                hint: 'Kullanıcıya özel mesaj...',
                icon: Icons.message_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text('Değişiklikleri Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}
