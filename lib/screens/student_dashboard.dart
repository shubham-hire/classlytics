import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import '../core/widgets/shared_ui_components.dart';

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
  late Future<Map<String, dynamic>> _categoryFeeFuture;

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
    _categoryFeeFuture = _apiService.fetchStudentCategoryFees();
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
              SharedUIComponents.buildChildIdentityCard(
                name: _user['name'] ?? 'Student',
                id: 'ID: ${_user['id'] ?? ''}',
                info: '${_user['dept'] ?? 'N/A'} • ${_user['current_year'] ?? 'N/A'}',
                gradientColors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
              ),
              const SizedBox(height: 24),

              SharedUIComponents.buildSectionTitle('Performance Overview'),
              const SizedBox(height: 16),

              // Attendance & Marks Quick Stats
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(child: _buildAttendanceCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMarksCard()),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SharedUIComponents.buildSectionTitle('AI Academic Insights'),
              const SizedBox(height: 16),
              _buildInsightsList(),
              const SizedBox(height: 32),
              
              SharedUIComponents.buildSectionTitle('Fee Status'),
              const SizedBox(height: 16),
              _buildFeeCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        String val = '--';
        if (snapshot.hasData) {
          val = '${snapshot.data?['percentage'] ?? 0}%';
        }
        return SharedUIComponents.buildStatCard(
          'Attendance',
          val,
          Icons.calendar_today,
          Colors.orange,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildMarksCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        String val = '--';
        if (snapshot.hasData) {
          val = '${snapshot.data?['average'] ?? 0}';
        }
        return SharedUIComponents.buildStatCard(
          'Avg Score',
          val,
          Icons.auto_awesome,
          Colors.purple,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
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
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
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
          children: list.map((insight) => Container(
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

  Widget _buildFeeCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _categoryFeeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?['status'] == 'NO_FEE_ASSIGNED') {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 12),
                Text('No fees assigned.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final fee = snapshot.data!;
        final status = fee['status'] ?? 'PENDING';
        final total = double.tryParse(fee['total_amount']?.toString() ?? '0') ?? 0;
        final paid = double.tryParse(fee['paid_amount']?.toString() ?? '0') ?? 0;
        final pending = total - paid;
        
        Color statusColor = Colors.orange;
        if (status == 'PAID') statusColor = Colors.green;
        else if (status == 'PARTIAL') statusColor = Colors.blue;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${fee['year']} · ${fee['category']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _feeDetail('Total', total, Colors.grey),
                  _feeDetail('Paid', paid, Colors.green),
                  _feeDetail('Pending', pending, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _feeDetail(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
