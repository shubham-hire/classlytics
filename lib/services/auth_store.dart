/// A simple singleton that persists the authenticated user's data
/// across route navigations when using GoRouter (which doesn't support
/// passing complex objects via path parameters).
class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  Map<String, dynamic>? _currentUser;

  /// Save user data after a successful login
  void setUser(Map<String, dynamic> user) {
    _currentUser = user;
  }

  /// Returns the currently logged-in user's data, or null if not logged in
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Returns a specific field from the user data
  dynamic get(String key) => _currentUser?[key];

  /// Clears user data on logout
  void clear() {
    _currentUser = null;
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
