import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import 'active_quiz_screen.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quizzes & Exams', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Active Quizzes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildQuizCard(
            context,
            title: 'Algebra Mid Term Quiz',
            subject: 'Math',
            duration: '30 mins',
            questions: 15,
            isLocked: false,
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          const Text(
            'Upcoming Exams',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildQuizCard(
            context,
            title: 'Newtonian Physics Exam',
            subject: 'Physics',
            duration: '90 mins',
            questions: 50,
            isLocked: true,
            date: 'Tomorrow, 10:00 AM',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, {required String title, required String subject, required String duration, required int questions, required bool isLocked, String? date, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLocked ? null : () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveQuizScreen()));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(subject, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    if (isLocked)
                      const Icon(Icons.lock_rounded, color: AppTheme.textSecondary, size: 20)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Available Now', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(duration, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.format_list_numbered_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('$questions qs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text('Starts: $date', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
