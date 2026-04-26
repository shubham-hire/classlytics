import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple singleton that persists the authenticated user's data
/// across route navigations when using GoRouter (which doesn't support
/// passing complex objects via path parameters).
class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  Map<String, dynamic>? _currentUser;

  /// Load user data from storage on app start
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }
  }

  /// Save user data after a successful login
  Future<void> setUser(Map<String, dynamic> user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user));
  }

  /// Returns the currently logged-in user's data, or null if not logged in
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Returns a specific field from the user data
  dynamic get(String key) => _currentUser?[key];

  /// Clears user data on logout
  Future<void> clear() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get user role safely
  String get role => (_currentUser?['role'] as String? ?? '').toLowerCase();

  /// Get student ID safely
  String get studentId => (_currentUser?['id'] ?? '').toString();

  /// Get child ID safely (for Parents)
  String get childId => (_currentUser?['child_id'] ?? '').toString();
}
