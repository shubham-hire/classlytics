import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';

class AdminRiskTrackerScreen extends StatefulWidget {
  const AdminRiskTrackerScreen({super.key});

  @override
  State<AdminRiskTrackerScreen> createState() => _AdminRiskTrackerScreenState();
}

class _AdminRiskTrackerScreenState extends State<AdminRiskTrackerScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _analysisData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchRiskAnalysis();
      setState(() {
        _analysisData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Proactive Risk Tracker',
      child: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.redAccent),
          const SizedBox(height: 24),
          Text(
            'Analyzing Database...',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning performance patterns and attendance trends...',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Analysis Failed', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadAnalysis, child: const Text('Retry Analysis')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final students = _analysisData?['students'] as List<dynamic>? ?? [];
    final aiReport = _analysisData?['aiAnalysis'] as String? ?? 'No report generated.';
    final riskCount = _analysisData?['riskCount'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Stats ───
          _buildSummaryCard(riskCount),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Student List ───
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Flagged Students', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (students.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildStudentCard(students[index]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // ─── AI Insights Panel ───
              Expanded(
                flex: 2,
                child: _buildAIInsightPanel(aiReport),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: count > 0 ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)] : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: count > 0 ? Colors.red.shade100 : Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.red.shade500 : Colors.green.shade500,
              shape: BoxShape.circle,
            ),
            child: Icon(count > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count > 0 ? '$count Students At Risk' : 'Perfect Academic Health',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: count > 0 ? Colors.red.shade900 : Colors.green.shade900),
              ),
              const SizedBox(height: 4),
              Text(
                count > 0 ? 'Urgent attention required for performance and attendance anomalies.' : 'No students are currently meeting at-risk criteria.',
                style: GoogleFonts.inter(color: count > 0 ? Colors.red.shade700 : Colors.green.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Text(student['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('ID: ${student['id']} • ${student['dept']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          _buildStat('Attendance', '${student['attendance_pct']}%', student['attendance_pct'] < 75 ? Colors.red : Colors.green),
          const SizedBox(width: 24),
          _buildStat('Avg Score', '${student['avg_score']}%', student['avg_score'] < 50 ? Colors.red : Colors.green),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => context.push('/admin/users/profile/${student['id']}'),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIInsightPanel(String report) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 12),
              Text('AI Intervention Strategy', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: MarkdownBody(
              data: report,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.6),
                strong: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Intervention suggestions are based on historical performance trends and attendance consistency.',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.thumb_up_alt_rounded, size: 48, color: Colors.green.shade200),
          const SizedBox(height: 16),
          const Text('All students are performing within safe thresholds.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
