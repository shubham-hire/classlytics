import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import 'package:main_app/services/api_service.dart';
import 'assignment_detail_screen.dart';
import 'ai_assistant_screen.dart';

class StudentTasksScreen extends StatefulWidget {
  const StudentTasksScreen({super.key});

  @override
  State<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends State<StudentTasksScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _assignmentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Use a global class ID or pull from session; using 'global' for now
    _assignmentsFuture = _apiService.fetchAssignments('global');
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStatus(String deadline) {
    try {
      final dt = DateTime.parse(deadline);
      final now = DateTime.now();
      if (dt.isBefore(now)) return 'Late';
      if (dt.difference(now).inDays <= 2) return 'Due Soon';
      return 'Pending';
    } catch (_) {
      return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Late':       return Colors.red;
      case 'Due Soon':   return const Color(0xFFEAB308);
      case 'Completed':  return Colors.green;
      default:           return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAssistantScreen()));
        },
        backgroundColor: Colors.orange.shade600,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            List<dynamic> allTasks = [];

            // Merge backend tasks with static hardcoded ones (for demo completeness)
            final staticFallback = [
              {'title': 'Physics Assignment', 'subject': 'Physics', 'deadline': DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10)},
              {'title': 'Math Worksheet', 'subject': 'Math', 'deadline': DateTime.now().add(const Duration(days: 4)).toIso8601String().substring(0, 10)},
              {'title': 'History Essay', 'subject': 'History', 'deadline': DateTime.now().subtract(const Duration(days: 4)).toIso8601String().substring(0, 10)},
              {'title': 'Chemistry Lab', 'subject': 'Chemistry', 'deadline': DateTime.now().subtract(const Duration(days: 6)).toIso8601String().substring(0, 10)},
            ];

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              allTasks = snapshot.data!;
            } else {
              allTasks = staticFallback;
            }

            // Apply search filter
            final filtered = allTasks.where((t) {
              final title = (t['title'] ?? '').toString().toLowerCase();
              final subject = (t['subject'] ?? '').toString().toLowerCase();
              return title.contains(_searchQuery) || subject.contains(_searchQuery);
            }).toList();

            final pending   = filtered.where((t) => _getStatus(t['deadline'] ?? '') == 'Pending').toList();
            final dueSoon   = filtered.where((t) => _getStatus(t['deadline'] ?? '') == 'Due Soon').toList();
            final late      = filtered.where((t) => _getStatus(t['deadline'] ?? '') == 'Late').toList();

            // Combine pending + due soon for the "Pending" tab
            final pendingTab = [...dueSoon, ...pending];

            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Summary counts
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        _buildSummaryChip('${pendingTab.length} Pending', AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        _buildSummaryChip('${dueSoon.length} Due Soon', const Color(0xFFEAB308)),
                        const SizedBox(width: 8),
                        _buildSummaryChip('${late.length} Late', Colors.red),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: [
                        Tab(text: 'Pending (${pendingTab.length})'),
                        const Tab(text: 'Completed'),
                        Tab(text: 'Late (${late.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task Lists
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              // Pending tab
                              pendingTab.isEmpty
                                  ? _buildEmpty('No pending tasks 🎉')
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: pendingTab.length,
                                      itemBuilder: (context, index) {
                                        final task = pendingTab[index];
                                        final status = _getStatus(task['deadline'] ?? '');
                                        return _buildTaskCard(
                                          context,
                                          task['title'] ?? 'Assignment',
                                          task['subject'] ?? 'General',
                                          task['deadline'] ?? '—',
                                          status,
                                          _statusColor(status),
                                        );
                                      },
                                    ),

                              // Completed tab (static for now)
                              ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  _buildTaskCard(context, 'History Essay', 'History', '10 Apr', 'Completed', Colors.green),
                                ],
                              ),

                              // Late tab
                              late.isEmpty
                                  ? _buildEmpty('No late tasks! Great work 🌟')
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: late.length,
                                      itemBuilder: (context, index) {
                                        final task = late[index];
                                        return _buildTaskCard(
                                          context,
                                          task['title'] ?? 'Assignment',
                                          task['subject'] ?? 'General',
                                          task['deadline'] ?? '—',
                                          'Late',
                                          Colors.red,
                                        );
                                      },
                                    ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String subject, String deadline, String status, Color statusColor) {
    // Format deadline nicely if it's an ISO string
    String displayDeadline = deadline;
    try {
      final dt = DateTime.parse(deadline);
      displayDeadline = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
    } catch (_) {}

    final isLate = status == 'Late';
    final isDueSoon = status == 'Due Soon';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLate
            ? Border(left: BorderSide(color: Colors.red, width: 4))
            : isDueSoon
                ? Border(left: BorderSide(color: const Color(0xFFEAB308), width: 4))
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isLate ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
                size: 14,
                color: isLate ? Colors.red : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isLate ? 'Overdue: $displayDeadline' : 'Deadline: $displayDeadline',
                style: TextStyle(
                  fontSize: 13,
                  color: isLate ? Colors.red : AppTheme.textSecondary,
                  fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignmentDetailScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLate ? Colors.red : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLate ? 'Submit Late' : 'View & Submit',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
