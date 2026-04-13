import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _attendanceFuture;
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<List<dynamic>> _insightsFuture;

  // Read authenticated user from the singleton store
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
  }

  @override
  Widget build(BuildContext context) {
    // Safety: if user is not logged in, redirect to login
    if (!AuthStore.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Student Hub', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              AuthStore.instance.clear();
              context.go('/login');
            },
          ),
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
              // Student Identity Card
              _buildProfileCard(),
              const SizedBox(height: 24),

              const Text(
                'Performance Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 16),

              // Attendance & Marks Quick Stats
              Row(
                children: [
                  Expanded(child: _buildAttendanceCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMarksCard()),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'AI Academic Insights',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 16),
              _buildInsightsList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = (_user['name'] as String? ?? 'Student');
    final id = (_user['id'] ?? '').toString();
    final dept = (_user['dept'] as String? ?? 'N/A');
    final year = (_user['current_year'] as String? ?? 'N/A');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ID: $id', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                if (dept != 'N/A' || year != 'N/A')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$dept • $year',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Attendance', '--', Icons.calendar_today, Colors.orange, loading: true);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Attendance', 'Err', Icons.calendar_today, Colors.orange);
        }
        final percentage = snapshot.data?['percentage'] ?? '--';
        return _buildStatCard('Attendance', '$percentage%', Icons.calendar_today, Colors.orange);
      },
    );
  }

  Widget _buildMarksCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard('Avg Score', '--', Icons.auto_awesome, Colors.purple, loading: true);
        }
        if (snapshot.hasError) {
          return _buildStatCard('Avg Score', 'Err', Icons.auto_awesome, Colors.purple);
        }
        final avg = snapshot.data?['average'] ?? '--';
        return _buildStatCard('Avg Score', '$avg', Icons.auto_awesome, Colors.purple);
      },
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color, {bool loading = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          loading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Text(
                  val,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInsightsList() {
    return FutureBuilder<List<dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Could not load insights: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 12),
                Text('No insights available yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  insight.toString(),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                )),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}
