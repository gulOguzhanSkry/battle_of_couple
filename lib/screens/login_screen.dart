import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Verification dialog state
  bool _showVerificationDialog = false;
  Timer? _resendTimer;
  int _resendCooldown = 0;
  
  // Animation
  late AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _heartAnimController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ==================== AUTH METHODS ====================

  Future<void> _signInWithGoogle() async {
    await _performAuth(() => _authService.signInWithGoogle());
  }

  Future<void> _signInWithApple() async {
    await _performAuth(() => _authService.signInWithApple());
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final credential = await _authService.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Create user profile
      if (credential.user != null) {
        await _userService.createUserProfile(credential.user!);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (e.toString() == AppStrings.emailVerificationRequired) {
        // Show verification dialog for unverified users
        _showVerificationDialogForLogin();
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
      
      if (mounted) {
        _showVerificationDialogAfterRegister();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performAuth(Future<dynamic> Function() authMethod) async {
    setState(() => _isLoading = true);

    try {
      final credential = await authMethod();

      if (credential == null || credential.user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Create user profile
      await _userService.createUserProfile(credential.user!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError(AppStrings.enterEmail);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.resetPasswordSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;
    
    try {
      final success = await _authService.sendVerificationToEmail(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.verifyEmailResent),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCooldown();
      }
    } catch (e) {
      _showError(e.toString());
    }
  }
  
  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
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

  // ==================== UI HELPERS ====================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showVerificationDialogAfterRegister() {
    _startResendCooldown();
    setState(() => _showVerificationDialog = true);
  }
  
  void _showVerificationDialogForLogin() {
    _startResendCooldown();
    setState(() => _showVerificationDialog = true);
  }
  
  void _closeVerificationDialog() {
    setState(() {
      _showVerificationDialog = false;
      _isRegisterMode = false;
    });
    _resendTimer?.cancel();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pink gradient background with hearts
          _buildBackground(),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _showVerificationDialog
                    ? _buildVerificationCard()
                    : _buildLoginCard(),
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          // Language Selector - Top Right (must be on top of everything)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildLanguageSelector(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B9D), // Soft pink
            Color(0xFFFF8E8E), // Light coral
            Color(0xFFFFB3BA), // Lighter pink
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating hearts animation
          ...List.generate(6, (index) {
            final positions = [
              const Offset(0.1, 0.1),
              const Offset(0.85, 0.15),
              const Offset(0.15, 0.7),
              const Offset(0.8, 0.6),
              const Offset(0.5, 0.05),
              const Offset(0.9, 0.85),
            ];
            return Positioned(
              left: MediaQuery.of(context).size.width * positions[index].dx,
              top: MediaQuery.of(context).size.height * positions[index].dy,
              child: AnimatedBuilder(
                animation: _heartAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.15 + (_heartAnimController.value * 0.1),
                    child: Transform.scale(
                      scale: 0.8 + (_heartAnimController.value * 0.2),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 30 + (index * 10).toDouble(),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageButton('🇹🇷', AppLanguage.turkish),
          _buildLanguageButton('🇬🇧', AppLanguage.english),
          _buildLanguageButton('🇮🇹', AppLanguage.italian),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String flag, AppLanguage language) {
    final isSelected = AppStrings.currentLanguage == language;
    return GestureDetector(
      onTap: () {
        setState(() {
          AppStrings.setLanguage(language);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B9D) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          flag,
          style: TextStyle(
            fontSize: 20,
            shadows: isSelected ? [
              const Shadow(color: Colors.white, blurRadius: 4),
            ] : null,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoginCard() {
    return Column(
      children: [
        // Logo with hearts
        _buildLogo(),
        const SizedBox(height: 16),
        
        // App title
        Text(
          AppStrings.appTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 24),
        
        // Login form card
        _buildFormCard(),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        size: 50,
        color: Color(0xFFFF6B9D),
      ),
    );
  }
  
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with heart
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRegisterMode ? Icons.person_add : Icons.login,
                  color: const Color(0xFFFF6B9D),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRegisterMode ? AppStrings.createAccount : AppStrings.login,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Name field (register only)
            if (_isRegisterMode) ...[
              _buildTextField(
                controller: _nameController,
                label: AppStrings.displayName,
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Email field
            _buildTextField(
              controller: _emailController,
              label: AppStrings.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.enterEmail;
                }
                if (!value.contains('@')) {
                  return AppStrings.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Password field
            _buildTextField(
              controller: _passwordController,
              label: AppStrings.password,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return AppStrings.passwordMinLength;
                }
                return null;
              },
            ),
            
            // Confirm Password (register only)
            if (_isRegisterMode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: AppStrings.confirmPassword,
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
            
            // Forgot Password (login only)
            if (!_isRegisterMode) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    AppStrings.forgotPassword,
                    style: const TextStyle(color: Color(0xFFFF6B9D)),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 8),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegisterMode ? _registerWithEmail : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isRegisterMode ? AppStrings.register : AppStrings.login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppStrings.orContinueWith,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Google Sign-In
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 20,
                  width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.black87),
                ),
                label: Text(AppStrings.signInWithGoogle),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
            ),
            
            // Apple Sign-In (iOS only)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signInWithApple,
                  icon: const Icon(Icons.apple, color: Colors.white),
                  label: Text(AppStrings.signInWithApple),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Toggle Register/Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRegisterMode ? AppStrings.alreadyHaveAccount : AppStrings.dontHaveAccount,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                TextButton(
                  onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                  child: Text(
                    _isRegisterMode ? AppStrings.login : AppStrings.register,
                    style: const TextStyle(
                      color: Color(0xFFFF6B9D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B9D)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
      ),
    );
  }
  
  Widget _buildVerificationCard() {
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
          // Email icon with animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 60,
              color: Color(0xFFFF6B9D),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            AppStrings.verifyEmailTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            AppStrings.verifyEmailDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          
          // Email address
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email, size: 16, color: Color(0xFFFF6B9D)),
                const SizedBox(width: 8),
                Text(
                  _emailController.text,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Check inbox hint
          Container(
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
          ),
          const SizedBox(height: 24),
          
          // Resend button with countdown
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resendCooldown > 0 ? null : _resendVerificationEmail,
              icon: const Icon(Icons.refresh),
              label: Text(
                _resendCooldown > 0
                    ? '${AppStrings.verifyEmailResendIn} $_resendCooldown ${AppStrings.verifyEmailSeconds}'
                    : AppStrings.resendVerification,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B9D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: _resendCooldown > 0 
                      ? Colors.grey.withValues(alpha: 0.3) 
                      : const Color(0xFFFF6B9D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // "I verified" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _closeVerificationDialog();
                // Try to login again
                _signInWithEmail();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(AppStrings.verifyEmailIVerified),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Back button
          TextButton.icon(
            onPressed: _closeVerificationDialog,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(AppStrings.cancel),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
