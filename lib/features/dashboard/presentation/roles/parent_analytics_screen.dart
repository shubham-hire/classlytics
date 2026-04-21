import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'package:classlytics/services/api_service.dart';
import 'package:classlytics/services/auth_store.dart';
import 'parent_teacher_chat_screen.dart';

class ParentAnalyticsScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const ParentAnalyticsScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<ParentAnalyticsScreen> createState() => _ParentAnalyticsScreenState();
}

class _ParentAnalyticsScreenState extends State<ParentAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _marksData;
  List<dynamic> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final childId = AuthStore.instance.currentUser?['child_id'] ?? '';
    if (childId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _apiService.fetchMarks(childId.toString()),
        _apiService.fetchInsights(childId.toString()).catchError((_) => ['No AI insights generated yet.']),
      ]);
      
      if (mounted) {
        setState(() {
          _marksData = results[0] as Map<String, dynamic>;
          _insights = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Performance & Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deep Dive AI Insight
              _buildAIDiagnostic(),
              const SizedBox(height: 32),

              const Text('Performance Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              
              // Mock Graph Area
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded, size: 64, color: AppTheme.primaryColor.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('Overall Grade Average: ${_marksData?['average'] ?? 'N/A'}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Performance has been steady over the last 3 months.', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text('Subject Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _buildSubjectBreakdown(),
            ],
          ),
        ),
    );
  }

  Widget _buildAIDiagnostic() {
    final aiText = _insights.isNotEmpty ? _insights[0].toString() : 'AI is analyzing your child\'s performance data to generate actionable insights.';
    
    // Simple mocked logic for demonstration of Action Plan
    final bool hasWarning = aiText.toLowerCase().contains('drop') || aiText.toLowerCase().contains('low') || aiText.toLowerCase().contains('improve');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.psychology_rounded, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('AI Performance Diagnostic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor))),
            ],
          ),
          const SizedBox(height: 16),
          Text(aiText, style: const TextStyle(color: AppTheme.textPrimary, height: 1.5, fontSize: 15)),
          const SizedBox(height: 20),
          if (hasWarning)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showActionPlan(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Generate Action Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ParentTeacherChatScreen(teacherId: widget.teacherId, teacherName: widget.teacherName)));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ask Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 18),
                label: const Text('On Track - Keep it up!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    final marksList = (_marksData?['marks'] as List?) ?? [];
    if (marksList.isEmpty) {
      return const Center(child: Text('No subject data found.'));
    }

    // Grouping marks by subject simplifies the UI
    Map<String, List<dynamic>> subjectMap = {};
    for (var m in marksList) {
      final sub = m['subject'] ?? 'Unknown';
      subjectMap.putIfAbsent(sub, () => []).add(m);
    }

    return Column(
      children: subjectMap.entries.map((e) {
        final subject = e.key;
        final scores = e.value;
        // Calculate average for subject
        double totalScore = 0;
        double maxScore = 0;
        for (var s in scores) {
          totalScore += s['score'];
          maxScore += s['max_score'];
        }
        final double pct = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
        
        // Mock trend
        final bool isUp = pct > 75;
        final Color trendColor = isUp ? Colors.green : Colors.red;
        final IconData trendIcon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${scores.length} Assessments Recorded', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: trendColor)),
                  const SizedBox(width: 8),
                  Icon(trendIcon, color: trendColor, size: 20),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showActionPlan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Action Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Based on recent performance data, here is an AI-generated recovery plan:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    SizedBox(height: 24),
                    _ActionPlanStep(number: "1", title: "Review Core Concepts", description: "The child struggled with the last two quizzes. Dedicate 30 mins daily to reviewing foundational chapters before moving to new ones."),
                    SizedBox(height: 16),
                    _ActionPlanStep(number: "2", title: "Complete Pending Tasks", description: "There is 1 overdue assignment. Supervise completion of this task by tomorrow evening to avoid further penalty."),
                    SizedBox(height: 16),
                    _ActionPlanStep(number: "3", title: "Schedule Teacher Meeting", description: "Since attendance has been low on Thursdays, message the teacher to understand if there is a scheduling conflict or loss of interest."),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ParentTeacherChatScreen(teacherId: widget.teacherId, teacherName: widget.teacherName)));
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                label: const Text('Execute Step 3 (Message Teacher)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPlanStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _ActionPlanStep({required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
            ],
          ),
        )
      ],
    );
  }
}
