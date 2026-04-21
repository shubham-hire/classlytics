import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import '../../../../services/auth_store.dart';
import '../../../../services/api_service.dart';
import 'parent_tasks_screen.dart';
import 'parent_analytics_screen.dart';
import 'parent_fee_screen.dart';
import 'parent_teacher_chat_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _marksData;
  List<dynamic>? _assignments;
  Map<String, dynamic>? _childInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    final parentId = AuthStore.instance.currentUser?['id'];
    final childId = AuthStore.instance.currentUser?['child_id'];
    if (childId == null || parentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _apiService.fetchAttendance(childId.toString()),
        _apiService.fetchMarks(childId.toString()),
        _apiService.fetchStudentAssignments(childId.toString()).catchError((_) => []),
        _apiService.fetchChildInfo(parentId.toString()).catchError((_) => <String, dynamic>{}),
      ]);
      
      if (mounted) {
        setState(() {
          _attendanceData = results[0] as Map<String, dynamic>?;
          _marksData = results[1] as Map<String, dynamic>?;
          _assignments = results[2] as List<dynamic>?;
          _childInfo = results[3] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading parent dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = AuthStore.instance.currentUser;
    final parentName = user?['name'] ?? 'Parent';
    final childName = _childInfo?['childName'] ?? user?['child_name'] ?? 'Child';
    final childClass = _childInfo?['className'] ?? 'Unassigned Class'; 
    final attendancePct = _attendanceData?['percentage']?.toString() ?? '85';
    final marks = (_marksData?['marks'] as List?) ?? [];
    int pendingTasks = 0;
    if (_assignments != null) {
      final now = DateTime.now();
      pendingTasks = _assignments!.where((a) {
        if (a['deadline'] == null) return false;
        try {
          final dt = DateTime.parse(a['deadline']);
          return dt.isAfter(now) || dt.isBefore(now); // Simplistic pending/late logic
        } catch (_) { return false; }
      }).length;
    }

    final hasAttendanceIssue = double.tryParse(attendancePct.replaceAll('%', '')) != null && 
                               double.parse(attendancePct.replaceAll('%', '')) < 75;
    
    // Simulate a marks drop condition manually based on recent scores
    bool hasMarksIssue = false;
    if (marks.length >= 2) {
       // simplistic mock metric: if the latest score is significantly worse than avg
       hasMarksIssue = marks.last['score'] < (marks.last['max_score'] * 0.6); 
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadChildData,
          backgroundColor: AppTheme.primaryColor,
          color: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hi, $parentName 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Parent of $childName', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.family_restroom_rounded, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 🚨 AI ALERTS ENGINE (TOP PRIORITY)
                if (hasAttendanceIssue)
                  _buildAIAlert(
                    'Attendance dropped below 75%', 
                    '$childName has missed recent classes. Consistent attendance is critical for academic success.',
                    Colors.red
                  ),
                if (hasMarksIssue)
                  _buildAIAlert(
                    'Performance declining in recent tests', 
                    '$childName scored poorly in the latest assessment. An intervention might be needed.',
                    const Color(0xFFEAB308)
                  ),
                if (hasAttendanceIssue || hasMarksIssue) const SizedBox(height: 24),

                // Quick Stats
                Row(
                  children: [
                    Expanded(child: _buildQuickStat('Attendance', '$attendancePct%', Icons.how_to_reg_rounded, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickStat('Avg Marks', '${_marksData?['average'] ?? 'N/A'}%', Icons.grade_rounded, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildQuickStat('Pending Tasks', pendingTasks.toString(), Icons.assignment_late_rounded, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildQuickStat('Fees Due', '₹0', Icons.account_balance_wallet_rounded, Colors.blue)), // Assuming 0 for quick stat default
                  ],
                ),
                const SizedBox(height: 32),

                // 🧭 Campus Modules
                const Text('Campus Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildModuleButton('Academic Progress', Icons.trending_up_rounded, ParentAnalyticsScreen(teacherId: _childInfo?['teacherId']?.toString() ?? 'fallback_teacher', teacherName: _childInfo?['teacherName'] ?? 'Class Teacher'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModuleButton('Assignments', Icons.book_rounded, const ParentTasksScreen())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildModuleButton('Fee Status', Icons.receipt_long_rounded, const ParentFeeScreen())),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModuleButton('Teacher Chat', Icons.chat_rounded, ParentTeacherChatScreen(teacherId: _childInfo?['teacherId']?.toString() ?? 'fallback_teacher', teacherName: _childInfo?['teacherName'] ?? 'Class Teacher'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionModuleButton('Request Leave', Icons.event_busy_rounded, _showLeaveRequestDialog),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 32),

                // 📊 Weekly Summary (AI)
                _buildWeeklySummary(),
                const SizedBox(height: 32),

                // 📅 Upcoming Assignments (Read Only summary)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ParentTasksScreen())),
                      child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_assignments == null || _assignments!.isEmpty)
                  const Center(child: Text('No recent assignments', style: TextStyle(color: AppTheme.textSecondary)))
                else
                  ..._assignments!.take(2).map((a) => _buildAssignmentRow(a['title'] ?? 'Assignment', a['subject'] ?? 'General', a['deadline'] ?? 'Pending')),

                const SizedBox(height: 100), // padding for scroll
              ],
            ),
          ),
        ),
      ),
      // Floating Action Buttons for Action Plan & Contact
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'contact_btn',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParentTeacherChatScreen(teacherId: _childInfo?['teacherId']?.toString() ?? 'fallback_teacher', teacherName: _childInfo?['teacherName'] ?? 'Class Teacher'))),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5))),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
                label: const Text('Contact Teacher', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'plan_btn',
                onPressed: _generateAIStudyPlan,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.psychology_rounded, color: Colors.white),
                label: const Text('AI Study Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAIAlert(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ $title', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary)
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Weekly AI Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: _apiService.fetchWeeklySummary(AuthStore.instance.currentUser?['child_id']?.toString() ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError) {
                return const Text('Summary not available.', style: TextStyle(color: Colors.white, fontSize: 14));
              }
              return Text(snapshot.data ?? 'No summary.', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildModuleButton(String title, IconData icon, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionModuleButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showLeaveRequestDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apply for leave for your child. It will be sent to the teacher for approval.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for leave',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final childId = AuthStore.instance.currentUser?['child_id'];
              final userId = AuthStore.instance.currentUser?['id'];
              if (childId == null || userId == null) return;
              
              Navigator.pop(context);
              try {
                // Sending tomorrow and day after as mock dates for now.
                final now = DateTime.now();
                final start = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];
                final end = now.add(const Duration(days: 2)).toIso8601String().split('T')[0];
                
                await _apiService.submitLeaveRequest(
                  userId: userId.toString(), 
                  studentId: childId.toString(), 
                  startDate: start, 
                  endDate: end, 
                  reason: reasonController.text.trim()
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted successfully.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }

  void _generateAIStudyPlan() {
    final childId = AuthStore.instance.currentUser?['child_id'];
    if (childId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('AI Home Study Plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _apiService.generateHomeStudyPlan(childId.toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('ClassAI is analyzing performance...', style: TextStyle(color: AppTheme.textSecondary))
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.data ?? 'No plan available.',
                      style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textPrimary),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentRow(String title, String subject, String deadline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
