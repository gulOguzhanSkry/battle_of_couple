import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_theme.dart';

/// Email verification dialog widget
/// 
/// Shows after registration to inform users they need to verify their email.
/// Includes resend functionality with cooldown timer.
class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onResend;
  final VoidCallback onVerified;
  final VoidCallback onCancel;
  final int initialCooldown;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.onResend,
    required this.onVerified,
    required this.onCancel,
    this.initialCooldown = 60,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  late int _resendCooldown;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _resendCooldown = widget.initialCooldown;
    _startCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResend() {
    if (_resendCooldown > 0) return;
    widget.onResend();
    setState(() => _resendCooldown = widget.initialCooldown);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmailIcon(),
          const SizedBox(height: 24),
          _buildTitle(),
          const SizedBox(height: 12),
          _buildDescription(),
          const SizedBox(height: 8),
          _buildEmailBadge(),
          const SizedBox(height: 24),
          _buildCheckInboxHint(),
          const SizedBox(height: 24),
          _buildResendButton(),
          const SizedBox(height: 12),
          _buildVerifiedButton(),
          const SizedBox(height: 16),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildEmailIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.loginGradientStart.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mark_email_unread_outlined,
        size: 60,
        color: AppTheme.loginGradientStart,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      AppStrings.verifyEmailTitle,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      AppStrings.verifyEmailDesc,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  Widget _buildEmailBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.email, size: 16, color: AppTheme.loginGradientStart),
          const SizedBox(width: 8),
          Text(
            widget.email,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInboxHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.verifyEmailCheckInbox,
              style: TextStyle(color: Colors.amber[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    final isDisabled = _resendCooldown > 0;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : _handleResend,
        icon: const Icon(Icons.refresh),
        label: Text(
          isDisabled
              ? '${AppStrings.verifyEmailResendIn} $_resendCooldown ${AppStrings.verifyEmailSeconds}'
              : AppStrings.resendVerification,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.loginGradientStart,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(
            color: isDisabled
                ? Colors.grey.withValues(alpha: 0.3)
                : AppTheme.loginGradientStart,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onVerified,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(AppStrings.verifyEmailIVerified),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.loginGradientStart,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton.icon(
      onPressed: widget.onCancel,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: Text(AppStrings.cancel),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey[600],
      ),
    );
  }
}
