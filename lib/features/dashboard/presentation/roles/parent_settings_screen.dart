import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'package:classlytics/services/auth_store.dart';
import 'package:go_router/go_router.dart';

class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final parentName = user?['name'] ?? 'Parent';
    final email = user?['email'] ?? 'parent@classlytics.com';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(parentName[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            _buildSettingTile(Icons.notifications_active_rounded, 'Push Notifications', 'Receive instant alerts on performance drops', true, (val) {}),
            _buildSettingTile(Icons.email_rounded, 'Email Digests', 'Weekly summary of your child\'s progress', true, (val) {}),
            _buildSettingTile(Icons.payment_rounded, 'Fee Reminders', 'Alerts before fee due dates', true, (val) {}),

            const SizedBox(height: 32),
            const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {},
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.lock_rounded, color: Colors.blue),
              ),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white,
            ),
            const SizedBox(height: 12),
            ListTile(
              onTap: () {
                AuthStore.instance.clear();
                context.go('/login');
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),
              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white,
            ),
            const SizedBox(height: 40),
            const Center(child: Text('Classlytics v1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}
