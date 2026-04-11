import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import 'assignment_detail_screen.dart';
import 'ai_assistant_screen.dart';

class StudentTasksScreen extends StatelessWidget {
  const StudentTasksScreen({super.key});

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
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
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
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Late'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Task List
              Expanded(
                child: TabBarView(
                  children: [
                    // Pending
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildTaskCard(context, 'Physics Assignment', 'Physics', '12 Apr', 'Pending', const Color(0xFFEAB308)), // Yellow
                        _buildTaskCard(context, 'Math Worksheet', 'Math', '14 Apr', 'Pending', AppTheme.primaryColor),
                      ],
                    ),
                    // Completed
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildTaskCard(context, 'History Essay', 'History', '10 Apr', 'Completed', Colors.green),
                      ],
                    ),
                    // Late
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildTaskCard(context, 'Chemistry Lab', 'Chemistry', '08 Apr', 'Late', Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String subject, String deadline, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Deadline: $deadline',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View & Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
