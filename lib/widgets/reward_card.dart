import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reward_model.dart';
import 'custom_scratch_card.dart';

class RewardCard extends StatelessWidget {
  final RewardModel reward;
  final VoidCallback? onScratchCompleted;
  final ValueChanged<Offset>? onScratchOffset;
  final bool isAdmin; // To potentially disable scratching or show extra admin controls
  final VoidCallback? onAssign; // Admin action

  const RewardCard({
    super.key,
    required this.reward,
    this.onScratchCompleted,
    this.onScratchOffset,
    this.isAdmin = false,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [reward.color, reward.color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(reward.icon, color: reward.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.amount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin && onAssign != null)
                   ElevatedButton(
                     onPressed: onAssign,
                     style: ElevatedButton.styleFrom(
                       foregroundColor: reward.color, backgroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: const Text('Ata'),
                   ),
              ],
            ),
          ),
          
          // 2. Scratch / Code Section
          // If Admin, just show the code directly or a placeholder.
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reward.message != null) ...[
                  Text(
                    '💌 "${reward.message}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (isAdmin)
                   _buildInternalContent(context) // Admins see content directly
                else if (reward.isScratched)
                  _buildRevealedCode(context, reward.code)
                else
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomScratchCard(
                        coverColor: const Color(0xFFF8BBD0), // Pink.shade100-ish
                        brushSize: 30, // Fat finger friendly
                        onThresholdReached: onScratchCompleted,
                        onScratchOffset: onScratchOffset,
                        child: _buildInternalContent(context),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                if (!isAdmin)
                  Center(
                    child: Text(
                      reward.isScratched 
                          ? 'Tebrikler!' 
                          : 'Kodu görmek için kazı',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalContent(BuildContext context) {
      return Container(
        color: const Color(0xFFFCE4EC), // Pink.shade50
        alignment: Alignment.center,
        // If admin, we show the code but maybe without copy button if in list
        // If user, scratch reveals this.
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildRevealedCode(context, reward.code, showCopy: !isAdmin),
        ),
      );
  }

  Widget _buildRevealedCode(BuildContext context, String code, {bool showCopy = true}) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SelectableText(
            code,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 2,
            ),
          ),
          if (showCopy) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kod kopyalandı!')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
