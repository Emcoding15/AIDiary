import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/record_screen.dart';
import 'screens/entry_details_screen.dart';
import 'screens/calendar_screen.dart';
import 'models/journal_entry.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/favorite_screen.dart';
import 'services/refresh_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request permissions
  await Permission.microphone.request();
  await Permission.storage.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for refresh manager
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Initialize the refresh manager
    RefreshManager.initialize(navigatorKey);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AI Diary',
      theme: AppTheme.getTheme(context),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const AIDiaryApp();
          }
          return const AuthScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AIDiaryApp extends StatefulWidget {
  const AIDiaryApp({super.key});

  @override
  State<AIDiaryApp> createState() => _AIDiaryAppState();
}

class _AIDiaryAppState extends State<AIDiaryApp> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );
    _animationController.value = 1.0;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    debugPrint('📱 Main: Tab switched from $_selectedIndex to $index');
    setState(() {
      _selectedIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }
  

    // Add a new journal entry (no-op, handled by HomeScreen/CalendarScreen)
    void _addJournalEntry(JournalEntry entry) {}

    // Update an existing journal entry (no-op, handled by HomeScreen/CalendarScreen)
    void _updateJournalEntry(JournalEntry updatedEntry) {}

  // Navigate to the record screen
  Future<void> _navigateToRecordScreen(BuildContext context) async {
    debugPrint('🎤 Main: Navigating to RecordScreen');
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RecordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnimationDuration,
      ),
    );

    debugPrint('🔙 Main: Returned from RecordScreen with result: ${result != null ? "JournalEntry" : "null"}');
    // Handle the returned journal entry
    if (result != null && result is JournalEntry) {
      debugPrint('📝 Main: Adding new journal entry to list');
      _addJournalEntry(result);

      // Use global refresh manager to refresh all screens
      debugPrint('🔄 Main: Refreshing all screens after new entry creation');
      RefreshManager.refreshAfterCreate();

      // Show a confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Journal entry saved successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Navigate to the entry details screen
  Future<void> _navigateToEntryDetailsScreen(BuildContext context, JournalEntry entry) async {
    debugPrint('🧭 Main: Navigating to EntryDetailsScreen for entry ${entry.id}');
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EntryDetailsScreen(
          entry: entry,
          onEntryUpdated: _updateJournalEntry,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnimationDuration,
      ),
    );
    
    debugPrint('🔙 Main: Returned from EntryDetailsScreen with result: $result');
    // If result is true, refresh all screens using global refresh manager
    if (result == true) {
      debugPrint('🔄 Main: Result is true, triggering global screen refresh...');
      RefreshManager.refreshAllScreens();
    } else {
      debugPrint('ℹ️ Main: Result is not true, no reload needed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onEntryTap: (entry) => _navigateToEntryDetailsScreen(context, entry),
        onEntryAdded: _addJournalEntry,
      ),
      CalendarScreen(
        onEntryTap: (entry) => _navigateToEntryDetailsScreen(context, entry),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rounded),
            color: Colors.amber,
            tooltip: 'Show favorite entries',
            onPressed: () async {
              debugPrint('⭐ Main: Navigating to FavoriteScreen');
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FavoriteScreen()),
              );
              
              // If changes were made in FavoriteScreen, refresh all screens
              if (result == true) {
                debugPrint('🔄 Main: Returned from FavoriteScreen with changes, refreshing all screens');
                RefreshManager.refreshAllScreens();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.lightShadow,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRecordScreen(context),
        elevation: 4,
        child: const Icon(Icons.mic_rounded),
      ),
    );
  }
}
