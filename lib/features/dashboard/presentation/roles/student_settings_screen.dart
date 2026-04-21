import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import '../../../../services/auth_store.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _studyReminders = true;
  bool _darkMode = false;

  Map<String, dynamic> get _user => AuthStore.instance.currentUser ?? {};

  @override
  Widget build(BuildContext context) {
    final name = _user['name'] ?? 'Student';
    final email = _user['email'] ?? 'No email';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Preferences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              
              _buildSwitchTile(
                'Notifications',
                'General alerts and updates',
                Icons.notifications_active_rounded,
                _notificationsEnabled,
                (val) => setState(() => _notificationsEnabled = val),
              ),
              _buildSwitchTile(
                'Study Reminders',
                'AI generated study nudges',
                Icons.schedule_rounded,
                _studyReminders,
                (val) => setState(() => _studyReminders = val),
              ),
              const SizedBox(height: 32),

              const Text(
                'Theme',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                'Dark Mode',
                'Toggle dark appearance (Coming Soon)',
                Icons.dark_mode_rounded,
                _darkMode,
                (val) => setState(() => _darkMode = val),
              ),
              
              const SizedBox(height: 64),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AuthStore.instance.clear();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ),
    );
  }
}
