import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/privacy_policy_service.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../widgets/privacy_acceptance_dialog.dart';

import 'games_screen.dart';
import 'profile_screen.dart';

/// Ana ekran - 2 ana sekme: Oyunlar, Profil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PrivacyPolicyService _privacyService = PrivacyPolicyService();
  bool _privacyChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyPolicyAcceptance();
  }

  Future<void> _checkPrivacyPolicyAcceptance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasAccepted = await _privacyService.hasUserAcceptedCurrentVersion(user.uid);
    
    if (!hasAccepted && mounted) {
      // Show privacy acceptance dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_privacyChecked) {
          _privacyChecked = true;
          PrivacyAcceptanceDialog.show(
            context,
            user.uid,
            () {
              // Privacy accepted callback
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gizlilik politikası kabul edildi ✓'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          );
        }
      });
    } else {
      _privacyChecked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const GamesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: AppStrings.homeGames,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.homeProfile,
          ),
        ],
      ),
    );
  }
}

