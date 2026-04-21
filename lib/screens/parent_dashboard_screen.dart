import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import '../core/widgets/shared_ui_components.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _attendanceFuture;
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<List<dynamic>> _announcementsFuture;
  late Future<List<dynamic>> _assignmentsFuture;

  // Read authenticated user (Parent) from AuthStore
  Map<String, dynamic> get _user => AuthStore.instance.currentUser ?? {};
  String get _childId => AuthStore.instance.childId;
  String get _childName => (_user['child_name'] ?? 'Your Child').toString();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    // If we have a childId, fetch their academic data
    if (_childId.isNotEmpty) {
      _attendanceFuture = _apiService.fetchAttendance(_childId);
      _marksFuture = _apiService.fetchMarks(_childId);
      _announcementsFuture = _apiService.fetchStudentAnnouncements(_childId);
      _assignmentsFuture = _apiService.fetchStudentAssignments(_childId);
    } else {
      _attendanceFuture = Future.value({});
      _marksFuture = Future.value({});
      _announcementsFuture = Future.value([]);
      _assignmentsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic Auth Check
    if (!AuthStore.instance.isAuthenticated || AuthStore.instance.role != 'parent') {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Parent Portal',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Reusing Teacher Dashboard Brand Color
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              AuthStore.instance.clear();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _refreshData()),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Student Overview Card
              SharedUIComponents.buildChildIdentityCard(
                name: _childName,
                id: 'Student ID: $_childId',
                info: '${_user['dept'] ?? 'General'} • ${_user['current_year'] ?? 'Batch 2024'}',
                gradientColors: [const Color(0xFF1E3A8A), const Color(0xFF334155)],
              ),
              const SizedBox(height: 24),

              // 2. Performance & Attendance Quick Stats
              SharedUIComponents.buildSectionTitle('Academic Snapshot'),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(child: _buildAttendanceSummary()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMarksSummary()),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Upcoming Assignments
              _buildAssignmentsSection(),
              const SizedBox(height: 32),

              // 4. Announcements
              _buildAnnouncementsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        String val = '--';
        Color color = Colors.grey;
        if (snapshot.hasData) {
          final p = snapshot.data!['percentage'] ?? 0;
          val = '$p%';
          color = (p as num) > 75 ? Colors.green : Colors.orange;
        }

        return SharedUIComponents.buildStatCard(
          'Attendance',
          val,
          Icons.check_circle_outline_rounded,
          color,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildMarksSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        String val = '--';
        if (snapshot.hasData) {
          val = '${snapshot.data!['average'] ?? 0}';
        }
        return SharedUIComponents.buildStatCard(
          'Avg. Score',
          val,
          Icons.auto_awesome_rounded,
          Colors.indigoAccent,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedUIComponents.buildSectionTitle('Upcoming Assignments'),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _assignmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) return _buildEmptyState('No pending assignments');

            return Column(
              children: list.take(3).map((a) => _buildAssignmentTile(a)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAssignmentTile(dynamic a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: Colors.orangeAccent, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] ?? 'Assignment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Subject: ${a['subject'] ?? 'General'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Due Date', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                (a['deadline'] ?? '').toString().split('T')[0],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedUIComponents.buildSectionTitle('School Announcements'),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) return _buildEmptyState('No new announcements');

            return Column(
              children: list.take(3).map((ann) => _buildAnnouncementCard(ann)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(dynamic ann) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ann['title'] ?? 'Notice',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ann['body'] ?? '',
            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

