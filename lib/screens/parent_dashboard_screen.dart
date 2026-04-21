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
  late Future<Map<String, dynamic>> _feesFuture;

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
      _feesFuture = _apiService.fetchChildFees(_childId);
    } else {
      _attendanceFuture = Future.value({});
      _marksFuture = Future.value({});
      _announcementsFuture = Future.value([]);
      _assignmentsFuture = Future.value([]);
      _feesFuture = Future.value({'summary': {}, 'assignments': []});
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

              // 3. Fee Summary Card
              _buildFeeSummaryCard(),
              const SizedBox(height: 24),

              // 4. Upcoming Assignments
              _buildAssignmentsSection(),
              const SizedBox(height: 32),

              // 5. Announcements
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
        onTap: (i) {
          if (i == 1) context.go('/parent/fees');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Fees'),
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

  Widget _buildFeeSummaryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedUIComponents.buildSectionTitle('Fees Overview'),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _feesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final summary = (snapshot.data?['summary'] as Map?)?.cast<String, dynamic>() ?? {};
            final assignments = (snapshot.data?['assignments'] as List?) ?? [];
            final totalDue = double.tryParse(summary['totalDue']?.toString() ?? '0') ?? 0;
            final totalPaid = double.tryParse(summary['totalPaid']?.toString() ?? '0') ?? 0;
            final totalPending = double.tryParse(summary['totalPending']?.toString() ?? '0') ?? 0;
            final progress = totalDue > 0 ? (totalPaid / totalDue).clamp(0.0, 1.0) : 0.0;

            return GestureDetector(
              onTap: () => context.go('/parent/fees'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Fees', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '₹${totalDue >= 1000 ? '${(totalDue / 1000).toStringAsFixed(1)}k' : totalDue.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _feeMiniStat('Paid', totalPaid, const Color(0xFF34D399)),
                            const SizedBox(width: 16),
                            _feeMiniStat('Due', totalPending, const Color(0xFFFCA5A5)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).toStringAsFixed(0)}% paid', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        Row(children: [
                          const Text('View Details', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white70),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _feeMiniStat(String label, double amount, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(
        '₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0)}',
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ],
  );

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

