import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_strings.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 80,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    AppStrings.noInternetTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    AppStrings.noInternetDesc,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Retry Button
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppStrings.noInternetRetry),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Connectivity wrapper widget
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.isNotEmpty && 
          results.any((result) => result != ConnectivityResult.none);
      setState(() {
        _isConnected = hasConnection;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isChecking = true);
    
    try {
      final results = await Connectivity().checkConnectivity();
      final hasConnection = results.isNotEmpty && 
          results.any((result) => result != ConnectivityResult.none);
      setState(() {
        _isConnected = hasConnection;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isConnected) {
      return NoInternetWidget(
        onRetry: _checkConnectivity,
      );
    }

    return widget.child;
  }
}
