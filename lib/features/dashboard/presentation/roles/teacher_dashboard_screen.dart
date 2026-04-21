import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import '../../../../screens/attendance_management_screen.dart';
import 'create_assignment_screen.dart';
import 'create_quiz_screen.dart';
import 'teacher_ai_assistant_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;
  late Future<Map<String, dynamic>> _profileFuture;

  String get _teacherId => AuthStore.instance.currentUser?['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dashboardFuture = _apiService.fetchDashboardData(teacherId: _teacherId.isNotEmpty ? _teacherId : null);
    _profileFuture = _apiService.fetchProfile(teacherId: _teacherId.isNotEmpty ? _teacherId : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherAIAssistantScreen()));
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _loadData()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        title: 'Take\nAttendance',
                        icon: Icons.fact_check_outlined,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceManagementScreen())),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        title: 'Create\nAssignment',
                        icon: Icons.add_task_rounded,
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()))
                            .then((_) => setState(() => _loadData())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        title: 'Create\nQuiz',
                        icon: Icons.quiz_rounded,
                        color: Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateQuizScreen()))
                            .then((_) => setState(() => _loadData())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),


                // Live Class Insights from backend
                const Text(
                  'Class Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLiveStats(),
                const SizedBox(height: 32),

                // At-Risk Students
                _buildAtRiskSection(),
                const SizedBox(height: 32),

                // Recent Submissions
                _buildRecentSubmissions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final name = snapshot.hasData ? snapshot.data!['name'] ?? 'Teacher' : 'Loading...';
        final dept = snapshot.hasData ? snapshot.data!['department'] ?? 'Department' : '';
        final initial = name.isNotEmpty && name != 'Loading...' ? name[0].toUpperCase() : 'T';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dept,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final totalStudents = data['totalStudents']?.toString() ?? '0';
        final avgAttendance = data['avgAttendance'] != null ? '${data['avgAttendance']}%' : 'N/A';
        final avgMarks = data['avgMarks'] != null ? '${data['avgMarks']}%' : 'N/A';
        final classCount = data['classCount']?.toString() ?? '0';

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Students', totalStudents, Icons.people_rounded, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Attendance', avgAttendance, Icons.calendar_today_rounded, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Avg Score', avgMarks, Icons.trending_up_rounded, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Classes', classCount, Icons.class_rounded, Colors.orange)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAtRiskSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final riskStudents = (snapshot.data?['riskStudents'] as List<dynamic>?) ?? [];

        if (riskStudents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'At-Risk Students',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${riskStudents.length} flagged',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...riskStudents.take(5).map((s) {
              final risk = s['risk'] ?? 'MEDIUM';
              final riskColor = risk == 'HIGH' ? Colors.red : risk == 'MEDIUM' ? Colors.orange : Colors.green;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: riskColor.withOpacity(0.1),
                          child: Text(
                            (s['name'] ?? 'S')[0].toUpperCase(),
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text(
                              'Attendance: ${s['attendancePct'] ?? 'N/A'}% | Score: ${s['avgMarks'] ?? 'N/A'}%',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(risk, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRecentSubmissions() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final submissions = (snapshot.data?['recentSubmissions'] as List<dynamic>?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Submissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text('Live', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (submissions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No submissions yet', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...submissions.map((s) {
                final submittedAt = s['submitted_at'] != null
                    ? _formatRelativeTime(DateTime.tryParse(s['submitted_at'].toString()))
                    : 'Unknown';
                return _buildSubmissionTile(
                  s['student_name'] ?? 'Student',
                  s['assignment_title'] ?? 'Assignment',
                  submittedAt,
                );
              }),
          ],
        );
      },
    );
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Submitted ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Submitted ${diff.inHours}hr ago';
    return 'Submitted ${diff.inDays}d ago';
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSubmissionTile(String name, String assignment, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.backgroundColor,
            child: Text(name.isNotEmpty ? name[0] : 'S', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(assignment, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
