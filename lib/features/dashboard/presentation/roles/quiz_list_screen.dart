import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import 'quiz_take_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _quizzesFuture;

  String get _studentId => AuthStore.instance.studentId;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = _api.fetchStudentQuizzes(_studentId);
  }

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
      body: FutureBuilder<List<dynamic>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading quizzes: ${snapshot.error}'));
          }
          final quizzes = snapshot.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(child: Text('No quizzes available at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildQuizCard(
                  context,
                  quiz: quiz,
                  color: Colors.blue,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, {required Map<String, dynamic> quiz, required Color color}) {
    final title = quiz['title'] ?? 'Unknown Quiz';
    final duration = quiz['duration_minutes'] ?? 30;
    // We might not have question count in the basic fetch, so just omit it if null or zero
    final hasSubmitted = quiz['has_submitted'] == true || quiz['has_submitted'] == 1;

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
          onTap: hasSubmitted
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakeScreen(
                        quizId: quiz['id'].toString(),
                        quizTitle: title,
                        durationMinutes: duration,
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _quizzesFuture = _api.fetchStudentQuizzes(_studentId);
                    });
                  });
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
                      child: Text('Quiz', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    if (hasSubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Submitted', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
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
                    Text('$duration mins', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

