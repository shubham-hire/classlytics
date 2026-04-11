import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class TeacherMessageHubScreen extends StatelessWidget {
  const TeacherMessageHubScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Teachers & Mentors', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTeacherChatCard(context, 'Dr. Sharma', 'Mathematics', 'Don\'t forget to submit the geometry assignment.', '10:30 AM', 2),
          const SizedBox(height: 12),
          _buildTeacherChatCard(context, 'Prof. Gupta', 'Science', 'Yes, the lab format is correct.', 'Yesterday', 0),
          const SizedBox(height: 12),
          _buildTeacherChatCard(context, 'Mr. Verma', 'History', 'Read chapter 4 before tomorrow\'s class.', 'Monday', 0),
        ],
      ),
    );
  }

  Widget _buildTeacherChatCard(BuildContext context, String name, String subject, String lastMessage, String time, int unread) {
    return GestureDetector(
      onTap: () {
        // In a real app, this would push to a specific chat view.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening chat with $name')));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                      Text(time, style: TextStyle(color: unread > 0 ? AppTheme.primaryColor : AppTheme.textSecondary, fontSize: 12, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subject, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unread > 0 ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 13, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
