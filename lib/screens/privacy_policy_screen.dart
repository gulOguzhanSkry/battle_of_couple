import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_strings.dart';
import '../theme/app_theme.dart';

/// Privacy Policy screen for AdMob compliance - Localized version
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.privacyPolicyTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppStrings.privacyPolicyLastUpdated,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              AppStrings.privacyPolicyTitle,
              AppStrings.privacyPolicyIntro,
            ),

            _buildSection(
              AppStrings.privacyPolicySection1Title,
              AppStrings.privacyPolicySection1Content,
            ),

            _buildSection(
              AppStrings.privacyPolicySection2Title,
              AppStrings.privacyPolicySection2Content,
            ),

            _buildHighlightSection(
              AppStrings.privacyPolicyAdmobTitle,
              AppStrings.privacyPolicyAdmobContent,
              linkText: AppStrings.privacyPolicyAdmobLink,
              onTap: () => _launchUrl('https://policies.google.com/privacy'),
            ),

            _buildSection(
              AppStrings.privacyPolicySection3Title,
              AppStrings.privacyPolicySection3Content,
            ),

            _buildSection(
              AppStrings.privacyPolicySection4Title,
              AppStrings.privacyPolicySection4Content,
            ),

            _buildSection(
              AppStrings.privacyPolicySection5Title,
              AppStrings.privacyPolicySection5Content,
            ),

            _buildSection(
              AppStrings.privacyPolicySection6Title,
              AppStrings.privacyPolicySection6Content,
            ),

            // Contact Section
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.privacyPolicyContactTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.privacyPolicyContactDesc,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchUrl('mailto:support@battleofcouples.com'),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'support@battleofcouples.com',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                AppStrings.privacyPolicyCopyright,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightSection(String title, String content, {String? linkText, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (onTap != null && linkText != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Text(
                linkText,
                style: const TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
