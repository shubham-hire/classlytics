import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import 'ai_assistant_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationCard(
            context,
            icon: Icons.warning_rounded,
            color: Colors.red,
            title: 'Early Warning Alert',
            message: 'Your math grade has fallen below 70%. A notification has been sent to your parents. Tap to consult the AI Study Planner to recover.',
            time: '1 hour ago',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
            },
          ),
          _buildNotificationCard(
            context,
            icon: Icons.assignment_turned_in_rounded,
            color: Colors.green,
            title: 'Assignment Graded',
            message: 'Mr. Einstein graded your History Essay. You scored 92/100.',
            time: '4 hours ago',
          ),
          _buildNotificationCard(
            context,
            icon: Icons.event_rounded,
            color: Colors.blue,
            title: 'New Quiz Scheduled',
            message: 'Algebra Mid Term Quiz added for Tomorrow at 10:00 AM.',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary))),
                          Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(message, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
