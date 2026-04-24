import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
// Removed Admin Dashboard Import
import 'roles/parent_dashboard_screen.dart';
import 'roles/teacher_dashboard_screen.dart';
import 'roles/student_dashboard_screen.dart';
import 'roles/student_tasks_screen.dart';
import 'roles/student_stats_screen.dart';
import 'roles/student_settings_screen.dart';
import 'roles/notifications_screen.dart';
import 'roles/parent_tasks_screen.dart';
import 'roles/parent_analytics_screen.dart';
import 'roles/parent_settings_screen.dart';

enum UserRole { student, teacher, parent }

class DashboardScreen extends StatefulWidget {
  final UserRole userRole;
  
  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (widget.userRole) {
      case UserRole.student:
        return _buildStudentTabs();
      case UserRole.teacher:
        return _currentIndex == 0 ? const TeacherDashboardScreen() : _buildPlaceholder();
      case UserRole.parent:
        return _buildParentTabs();
      // Removed Admin Case
    }
  }

  Widget _buildParentTabs() {
    switch (_currentIndex) {
      case 0:
        return const ParentDashboardScreen();
      case 1:
        return const ParentTasksScreen();
      case 2:
        return const ParentAnalyticsScreen();
      case 3:
        return const ParentSettingsScreen();
      default:
        return const ParentDashboardScreen();
    }
  }

  Widget _buildStudentTabs() {
    switch (_currentIndex) {
      case 0:
        return const StudentDashboardScreen();
      case 1:
        return const StudentTasksScreen();
      case 2:
        return const StudentStatsScreen();
      case 3:
        return const StudentSettingsScreen();
      default:
        return const StudentDashboardScreen();
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text('Placeholder for Tab $_currentIndex', style: const TextStyle(color: AppTheme.textSecondary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 10),
            const Text('Classlytics', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.accentColor.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.primaryColor),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primaryColor),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
