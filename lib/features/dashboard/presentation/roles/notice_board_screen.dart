import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notices & Events', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNoticeCard('Annual Sports Meet 2026', 'Sports Dept', 'Starts 20 Apr, 09:00 AM', true, Icons.sports_basketball_rounded, Colors.orange),
          const SizedBox(height: 16),
          _buildNoticeCard('Final Exam Schedule Released', 'Examinations', 'Valid from 10 May', false, Icons.assignment_rounded, Colors.red),
          const SizedBox(height: 16),
          _buildNoticeCard('Tech Fest Registration', 'Computer Dept', 'Ends 25 Apr', true, Icons.computer_rounded, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(String title, String department, String date, bool isEvent, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isEvent ? 'EVENT' : 'NOTICE', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Issued by $department', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
