import 'package:flutter/material.dart';

/// Global refresh manager to handle UI updates across all screens
/// 
/// Usage:
/// 1. Initialize with RefreshManager.initialize(navigatorKey) in main.dart
/// 2. Make screens extend RefreshableScreen mixin and implement _onRefresh()
/// 3. Call RefreshManager.refreshAfterSave(), refreshAfterDelete(), etc. after operations
/// 
/// This centralized approach makes it easy to:
/// - Add new screens that automatically participate in refresh
/// - Ensure all screens stay in sync after data changes
/// - Scale the app without worrying about manual refresh logic
/// 
/// Example:
/// ```dart
/// // After saving an entry
/// await FirebaseService().saveJournalEntry(entry);
/// RefreshManager.refreshAfterSave();
/// 
/// // After deleting an entry  
/// await FirebaseService().deleteJournalEntry(entryId);
/// RefreshManager.refreshAfterDelete();
/// ```
class RefreshManager {
  static final RefreshManager _instance = RefreshManager._internal();
  factory RefreshManager() => _instance;
  RefreshManager._internal();

  // Global keys for accessing screen states
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final List<VoidCallback> _refreshCallbacks = [];

  /// Initialize the refresh manager with the navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Register a refresh callback for a screen
  static void registerRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.add(callback);
  }

  /// Unregister a refresh callback when screen is disposed
  static void unregisterRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.remove(callback);
  }

  /// Clear all registered callbacks (useful for app lifecycle management)
  static void clearAllCallbacks() {
    _refreshCallbacks.clear();
  }

  /// Refresh all registered screens
  static void refreshAllScreens() {
    for (final callback in _refreshCallbacks) {
      try {
        callback();
      } catch (e) {
        // Silently handle any errors in refresh callbacks
        debugPrint('Error in refresh callback: $e');
      }
    }
  }

  /// Refresh specific screens by type (optional advanced feature)
  static void refreshScreensOfType(Type screenType) {
    // This could be extended in the future if needed
    refreshAllScreens();
  }

  /// Convenience method for common operations that need refresh
  static void refreshAfterSave() {
    refreshAllScreens();
  }

  /// Convenience method for common operations that need refresh
  static void refreshAfterDelete() {
    refreshAllScreens();
  }

  /// Convenience method for common operations that need refresh
  static void refreshAfterCreate() {
    refreshAllScreens();
  }

  /// Convenience method for common operations that need refresh
  static void refreshAfterFavoriteToggle() {
    refreshAllScreens();
  }

  /// Convenience method for common operations that need refresh
  static void refreshAfterNotesUpdate() {
    refreshAllScreens();
  }

  /// Get the navigator context for navigation operations
  static BuildContext? get navigatorContext => _navigatorKey?.currentContext;

  /// Check if the refresh manager is properly initialized
  static bool get isInitialized => _navigatorKey != null;
}

/// Mixin for screens that need to participate in global refresh
mixin RefreshableScreen<T extends StatefulWidget> on State<T> {
  late VoidCallback _refreshCallback;

  @override
  void initState() {
    super.initState();
    _refreshCallback = onRefresh;
    RefreshManager.registerRefreshCallback(_refreshCallback);
  }

  @override
  void dispose() {
    RefreshManager.unregisterRefreshCallback(_refreshCallback);
    super.dispose();
  }

  /// Implement this method in your screen to define refresh behavior
  void onRefresh();
}
