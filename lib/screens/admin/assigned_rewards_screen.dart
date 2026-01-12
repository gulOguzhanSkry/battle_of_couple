import 'package:flutter/material.dart';
import '../../services/reward_service.dart';

class AssignedRewardsScreen extends StatefulWidget {
  const AssignedRewardsScreen({super.key});

  @override
  State<AssignedRewardsScreen> createState() => _AssignedRewardsScreenState();
}

class _AssignedRewardsScreenState extends State<AssignedRewardsScreen> {
  final RewardService _rewardService = RewardService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Atama Geçmişi'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _rewardService.getAllAssignedRewardsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rewards = snapshot.data ?? [];

          if (rewards.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz ödül atanmamış.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return _buildRewardHistoryCard(reward);
            },
          );
        },
      ),
    );
  }

  Widget _buildRewardHistoryCard(Map<String, dynamic> reward) {
    final title = reward['title'] ?? 'Bilinmiyor';
    final amount = reward['amount'] ?? '';
    final isScratched = reward['isScratched'] ?? false;
    final isTeamReward = reward['isTeamReward'] ?? false;
    final targetIds = List<String>.from(reward['targetIds'] ?? []);
    final assignedAt = reward['assignedAt'] != null
        ? DateTime.tryParse(reward['assignedAt'])
        : null;
    final rewardId = reward['id'] ?? '';
    final templateId = reward['templateId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isScratched ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isScratched ? Icons.check : Icons.card_giftcard,
            color: isScratched ? Colors.green : Colors.orange,
          ),
        ),
        title: Text('$title - $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTeamReward 
                  ? '👫 Çift ödülü (${targetIds.length} kişi)' 
                  : '👤 Bireysel ödül',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (assignedAt != null)
              Text(
                '📅 ${_formatDate(assignedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'unassign' && templateId.isNotEmpty) {
              await _confirmUnassign(rewardId, templateId, title);
            } else if (action == 'delete') {
              await _confirmDelete(rewardId, title);
            }
          },
          itemBuilder: (ctx) => [
            if (templateId.isNotEmpty && !isScratched)
              const PopupMenuItem(
                value: 'unassign',
                child: Row(
                  children: [
                    Icon(Icons.undo, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Geri Al'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isScratched ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isScratched ? 'Kazındı' : 'Bekliyor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isScratched ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmUnassign(String rewardId, String templateId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hediye Çekini Geri Al'),
        content: Text('"$title" hediye çekini geri almak istediğinizden emin misiniz? Tekrar atanabilir hale gelecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Geri Al'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _rewardService.unassignReward(rewardId: rewardId, templateId: templateId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hediye çeki geri alındı.'), backgroundColor: Colors.green),
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

  Future<void> _confirmDelete(String rewardId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödülü Sil'),
        content: Text('"$title" ödülünü kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _rewardService.deleteAssignedReward(rewardId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ödül silindi.')),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
