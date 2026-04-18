import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import 'detailed_analytics_screen.dart';
import 'library_screen.dart';
import 'academic_planning_screen.dart';
import 'notice_board_screen.dart';
import 'certificates_screen.dart';
import 'feedback_screen.dart';
import 'quiz_list_screen.dart';
import 'ai_assistant_screen.dart';
import 'teacher_message_hub_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _attendanceFuture;
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<List<dynamic>> _insightsFuture;
  late Future<Map<String, dynamic>> _feeStatusFuture;
  late Future<List<dynamic>> _assignmentsFuture;

  Map<String, dynamic> get _user => AuthStore.instance.currentUser ?? {};
  String get _studentId => AuthStore.instance.studentId;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _attendanceFuture = _apiService.fetchAttendance(_studentId);
    _marksFuture = _apiService.fetchMarks(_studentId);
    _insightsFuture = _apiService.fetchInsights(_studentId);
    _feeStatusFuture = _apiService.fetchFeeStatus(_studentId);
    _assignmentsFuture = _apiService.fetchStudentAssignments(_studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChatOptions(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.forum_rounded, color: Colors.white),
        label: const Text('Chat & Help', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _refreshData();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Segment
                _buildDynamicHeader(),
                const SizedBox(height: 40),

                // Quick Stats
                Row(
                  children: [
                    Expanded(child: _buildAttendanceStat()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMarksStat()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQuickStat('2', 'Pending', Icons.pending_actions_rounded, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 32),

                // Financial Status
                _buildFeeCard(),
                const SizedBox(height: 48),

                // Campus Modules
                const Text(
                  'Campus Modules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildModuleButton(context, 'Academic Planning', Icons.calendar_month_rounded, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AcademicPlanningScreen()));
                    }),
                    _buildModuleButton(context, 'Library', Icons.local_library_rounded, Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryScreen()));
                    }),
                    _buildModuleButton(context, 'Exams & Quizzes', Icons.quiz_rounded, Colors.orange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizListScreen()));
                    }),
                    _buildModuleButton(context, 'Notice Board', Icons.campaign_rounded, Colors.red, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeBoardScreen()));
                    }),
                    _buildModuleButton(context, 'Result Analysis', Icons.insights_rounded, Colors.green, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailedAnalyticsScreen()));
                    }),
                    _buildModuleButton(context, 'Certificates', Icons.card_membership_rounded, Colors.amber.shade600, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CertificatesScreen()));
                    }),
                    _buildModuleButton(context, 'Feedback', Icons.feedback_rounded, AppTheme.primaryColor, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                    }),
                  ],
                ),
                const SizedBox(height: 48),

                // AI Insights
                _buildAIInsightsSection(),
                const SizedBox(height: 48),

                // Upcoming Assignments from Backend
                _buildUpcomingAssignmentsSection(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicHeader() {
    final name = _user['name'] ?? 'Student';
    final id = _user['id'] ?? 'N/A';
    final dept = _user['dept'] ?? 'General';
    final year = _user['current_year'] ?? '1st Year';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF5C6DF7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        id.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '2025-26',
                    style: TextStyle(
                      color: Color(0xFF5C6DF7),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Department',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dept,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Year / Class',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        year,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        final val = snapshot.hasData ? '${snapshot.data!['percentage']}%' : '--%';
        return _buildQuickStat(val, 'Attendance', Icons.calendar_today_rounded, Colors.blue);
      },
    );
  }

  Widget _buildMarksStat() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        final val = snapshot.hasData ? '${snapshot.data!['average']}%' : '--%';
        return _buildQuickStat(val, 'Avg Score', Icons.trending_up_rounded, Colors.green);
      },
    );
  }

  Widget _buildQuickStat(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _feeStatusFuture,
      builder: (context, snapshot) {
        final total = snapshot.hasData ? snapshot.data!['totalFee'] ?? 50000 : 50000;
        final paid = snapshot.hasData ? snapshot.data!['paidAmount'] ?? 0 : 0;
        final pending = snapshot.hasData ? snapshot.data!['pendingAmount'] ?? 50000 : 50000;
        final semester = snapshot.hasData ? snapshot.data!['semester'] ?? 'Sem 1' : '...';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade50.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.account_balance_wallet_rounded, color: Colors.green.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(semester.toString(), style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFeeItem('Total Fee', '₹${_formatFee(total)}', Colors.blue),
                  _buildFeeItem('Paid', '₹${_formatFee(paid)}', Colors.green),
                  _buildFeeItem('Pending', '₹${_formatFee(pending)}', pending > 0 ? Colors.orange : Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFee(dynamic value) {
    final num amount = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildFeeItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    return FutureBuilder<List<dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        String msg = "Fetching your academic performance insights...";
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          msg = snapshot.data![0].toString();
        } else if (snapshot.hasError) {
          msg = "Unable to connect to AI Insight service.";
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade50.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.psychology_alt_rounded, color: Colors.orange.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Insight',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      msg,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAssignmentsSection() {
    return FutureBuilder<List<dynamic>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Assignments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (snapshot.hasError || assignments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No assignments yet. Check back soon!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...assignments.take(5).map((a) {
                final bool submitted = (a['submitted'] == 1 || a['submitted'] == true);
                final deadline = a['deadline'] != null
                    ? DateTime.tryParse(a['deadline'].toString())
                    : null;
                final isOverdue = deadline != null && deadline.isBefore(DateTime.now()) && !submitted;
                final Color statusColor = submitted
                    ? Colors.green
                    : isOverdue ? Colors.red : AppTheme.primaryColor;
                final String statusText = submitted ? 'Submitted' : isOverdue ? 'Overdue' : 'Pending';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUpcomingTaskCard(
                    a['title'] ?? 'Assignment',
                    deadline != null
                        ? '${deadline.day} ${_monthName(deadline.month)}, ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}'
                        : 'No deadline',
                    statusText,
                    statusColor,
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  Widget _buildUpcomingTaskCard(String title, String deadline, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      deadline,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    double width = (MediaQuery.of(context).size.width - 48 - 32) / 3; 
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Who do you need to talk to?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherMessageHubScreen()));
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.school_rounded, color: Colors.blue),
              ),
              title: const Text('Message Friends and Teachers', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ask doubts or request help directly.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
            const Divider(),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAssistantScreen()));
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.purple),
              ),
              title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant help and doubt solving.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
