import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_strings.dart';
import '../services/privacy_policy_service.dart';
import '../theme/app_theme.dart';

/// Full-screen Privacy Policy acceptance dialog
/// Must be accepted to continue using the app
class PrivacyAcceptanceDialog extends StatefulWidget {
  final String userId;
  final VoidCallback onAccepted;

  const PrivacyAcceptanceDialog({
    super.key,
    required this.userId,
    required this.onAccepted,
  });

  /// Show this dialog - cannot be dismissed without acceptance
  static Future<void> show(BuildContext context, String userId, VoidCallback onAccepted) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrivacyAcceptanceDialog(
        userId: userId,
        onAccepted: onAccepted,
      ),
    );
  }

  @override
  State<PrivacyAcceptanceDialog> createState() => _PrivacyAcceptanceDialogState();
}

class _PrivacyAcceptanceDialogState extends State<PrivacyAcceptanceDialog> {
  final PrivacyPolicyService _policyService = PrivacyPolicyService();
  bool _isLoading = false;
  bool _hasScrolledToEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollEnd);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollEnd() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToEnd) {
        setState(() => _hasScrolledToEnd = true);
      }
    }
  }

  Future<void> _acceptPolicy() async {
    setState(() => _isLoading = true);
    try {
      await _policyService.acceptPrivacyPolicy(
        userId: widget.userId,
        version: PrivacyPolicyService.currentVersion,
      );
      widget.onAccepted();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.privacy_tip, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.privacyPolicyTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v${PrivacyPolicyService.currentVersion}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.privacyPolicyLastUpdated,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(AppStrings.privacyPolicyIntro,
                        style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 20),

                    _buildSection(AppStrings.privacyPolicySection1Title,
                        AppStrings.privacyPolicySection1Content),
                    _buildSection(AppStrings.privacyPolicySection2Title,
                        AppStrings.privacyPolicySection2Content),
                    
                    // AdMob highlight
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Color(0xFFE91E63), width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.privacyPolicyAdmobTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(AppStrings.privacyPolicyAdmobContent,
                              style: const TextStyle(height: 1.4)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _launchUrl('https://policies.google.com/privacy'),
                            child: Text(
                              AppStrings.privacyPolicyAdmobLink,
                              style: const TextStyle(color: Color(0xFFE91E63)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSection(AppStrings.privacyPolicySection3Title,
                        AppStrings.privacyPolicySection3Content),
                    _buildSection(AppStrings.privacyPolicySection4Title,
                        AppStrings.privacyPolicySection4Content),
                    _buildSection(AppStrings.privacyPolicySection5Title,
                        AppStrings.privacyPolicySection5Content),
                    _buildSection(AppStrings.privacyPolicySection6Title,
                        AppStrings.privacyPolicySection6Content),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        AppStrings.privacyPolicyCopyright,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with accept button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  if (!_hasScrolledToEnd)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '↓ Devam etmek için aşağı kaydırın',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasScrolledToEnd && !_isLoading ? _acceptPolicy : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Okudum ve Kabul Ediyorum',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
