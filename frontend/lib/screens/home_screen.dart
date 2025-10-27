import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/connectivity_indicator.dart';
import 'file_explorer_screen.dart';

/// Home screen shown after successful authentication
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressed;

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = context.read<AuthService>();

    try {
      await authService.signOut();
      // Navigation will be handled by the auth state listener in main.dart
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle back button press at app level
  Future<bool> _onWillPop() async {
    try {
      // First, let the FileExplorerScreen handle navigation
      final shouldExitFromExplorer =
          await FileExplorerNavigationHandler.handleBackNavigation();

      // If FileExplorerScreen says it's at root level, handle double-back-to-exit
      if (shouldExitFromExplorer) {
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Press back again to exit ScholarMate'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
          return false;
        }
        return true; // Allow exit on second back press
      }

      return false; // FileExplorerScreen handled the navigation
    } catch (e) {
      // If there's any error, allow exit to prevent getting stuck
      debugPrint('Error in back navigation: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Use SystemNavigator to exit the app properly
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ScholarMate'),
          elevation: 0,
          automaticallyImplyLeading: false, // Remove default back button
          actions: [
            // Connectivity indicator
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: ConnectivityIndicator(),
            ),
            // User Profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'signout') {
                    _handleSignOut(context);
                  }
                },
                child: Row(
                  children: [
                    if (user.photoUrl != null)
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(user.photoUrl!),
                        backgroundColor: Colors.grey[300],
                      )
                    else
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              user.email.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (MediaQuery.of(context).size.width > 600)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: const FileExplorerScreen(),
      ),
    );
  }
}
