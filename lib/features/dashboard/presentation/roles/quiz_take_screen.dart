import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import '../../../../core/theme/app_theme.dart';

class QuizTakeScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int durationMinutes;

  const QuizTakeScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.durationMinutes,
  });

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;

  // Answers: { questionId -> 'A'|'B'|'C'|'D' }
  final Map<String, String> _answers = {};

  // Timer
  late Timer _timer;
  late int _secondsLeft;
  final DateTime _startTime = DateTime.now();

  Map<String, dynamic>? _result;

  String get _studentId => AuthStore.instance.studentId;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;
    _loadQuestions();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer.cancel();
        if (!_submitted) _submitQuiz(autoSubmit: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await _api.fetchQuizQuestions(widget.quizId);
      setState(() {
        _questions = data['questions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_submitted) return;
    final unanswered = _questions.length - _answers.length;
    if (!autoSubmit && unanswered > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit Quiz?'),
          content: Text('You have $unanswered unanswered question${unanswered > 1 ? 's' : ''}. Submit anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer.cancel();

    try {
      final timeTaken = DateTime.now().difference(_startTime).inSeconds;
      final result = await _api.submitQuiz(
        quizId: widget.quizId,
        studentId: _studentId,
        answers: _answers,
        timeTakenSeconds: timeTaken,
      );
      setState(() {
        _result = result;
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_secondsLeft < 60) return Colors.red;
    if (_secondsLeft < 300) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _submitted,
      onPopInvoked: (didPop) {
        if (!didPop && !_submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot leave during a quiz. Submit to exit.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: _submitted,
          title: Text(widget.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0.5,
          actions: [
            if (!_submitted)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _timerColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                    const SizedBox(width: 4),
                    Text(_timerText, style: TextStyle(fontWeight: FontWeight.bold, color: _timerColor)),
                  ],
                ),
              ),
          ],
        ),
        body: _submitted ? _buildResultView() : _buildQuizView(),
        bottomNavigationBar: _submitted
            ? null
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitQuiz(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Submit Quiz  (${_answers.length}/${_questions.length} answered)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_questions.isEmpty) return const Center(child: Text('No questions found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (ctx, i) {
        final q = _questions[i];
        final qId = q['id'] as String;
        final opts = {'A': q['option_a'], 'B': q['option_b'], 'C': q['option_c'], 'D': q['option_d']};
        final selected = _answers[qId];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text('Q${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text('${q['marks']} mark${(q['marks'] as int) > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Text(q['question'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary, height: 1.4)),
              const SizedBox(height: 14),
              ...opts.entries.map((entry) {
                final isSelected = selected == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _answers[qId] = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value as String, style: TextStyle(color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultView() {
    final score = _result?['score'] ?? 0;
    final total = _result?['totalMarks'] ?? _questions.length;
    final pct = _result?['percentage'] ?? 0;
    final breakdown = (_result?['resultBreakdown'] as Map?)?.cast<String, dynamic>() ?? {};

    final color = pct >= 80 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Score card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.shade600, color.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(pct >= 80 ? '🎉 Excellent!' : pct >= 50 ? '👍 Good Effort!' : '📚 Keep Practicing!',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$score / $total', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              Text('$pct% Score', style: const TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Question review
        const Text('Question Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),

        ..._questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          final qId = q['id'] as String;
          final qBreak = breakdown[qId];
          final isCorrect = qBreak?['correct'] == true;
          final studentAns = qBreak?['studentAnswer'];
          final correctAns = qBreak?['correctAnswer'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? Colors.green : Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text('Q${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(q['question'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
                if (!isCorrect) ...[
                  const SizedBox(height: 6),
                  Text('Your answer: $studentAns', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  Text('Correct answer: $correctAns', style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}
