import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/base_service.dart';
import 'services/firebase_service.dart';
import 'services/mock_firebase_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'widgets/no_internet_widget.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Turkish date formatting
    await initializeDateFormatting('tr_TR', null);
    
    // Load environment variables
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Continue even if .env fails - use defaults
    debugPrint('Environment initialization error: $e');
  }
  
  // Initialize Firebase for production mode
  try {
    if (!EnvConfig.useMockData) {
      await Firebase.initializeApp();

      // Initialize App Check
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest,
      );
      
      // Enable offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // Initialize notification service (non-blocking)
      NotificationService().initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('NotificationService initialization timed out');
        },
      ).catchError((e) {
        debugPrint('NotificationService initialization error: $e');
      });
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide BaseService - use mock or real based on environment
        Provider<BaseService>(
          create: (_) => EnvConfig.useMockData 
              ? MockFirebaseService()
              : FirebaseService(),
        ),
        // Provide AuthService
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Provide UserService
        Provider<UserService>(
          create: (_) => UserService(),
        ),
      ],
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppStrings.languageNotifier,
        builder: (context, language, child) {
          return MaterialApp(
            title: 'Battle of Couples',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: ConnectivityWrapper(
              child: AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

// Auth wrapper to check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        
        if (user != null) {
          // Check if email/password user needs verification
          // OAuth users (Google, Apple) are considered verified
          final isEmailPasswordUser = user.providerData.any(
            (provider) => provider.providerId == 'password',
          );
          
          if (isEmailPasswordUser && !user.emailVerified) {
            // Email/password user not verified - send to login screen
            return const LoginScreen();
          }
          
          return HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
