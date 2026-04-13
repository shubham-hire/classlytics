import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _apiService.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Deep Blue primary color
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Text('1', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/announcements'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.push('/teacher-profile'),
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final totalStudents = data['totalStudents'].toString();
          final avgAttendance = "${data['avgAttendance']}%";
          final avgMarks = data['avgMarks'].toString();
          final riskStudents = data['riskStudents'] as List;
          final scheduleData = data['schedule'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Overview'),
                    TextButton.icon(
                      onPressed: () => context.push('/my-classes'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('My Classes'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSummaryCard(
                      value: totalStudents,
                      label: 'Students',
                      icon: Icons.people_outline_rounded,
                      color: Colors.blueAccent,
                      bgColor: const Color(0xFFE3F2FD),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      value: avgAttendance,
                      label: 'Attendance',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      value: avgMarks,
                      label: 'Avg Marks',
                      icon: Icons.bar_chart_rounded,
                      color: Colors.orange,
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                _buildTodaysSchedule(scheduleData),
                const SizedBox(height: 40),

                _buildQuickActions(),
                const SizedBox(height: 40),

                _buildPendingTasks(),
                const SizedBox(height: 40),

                _buildAnnouncementsFeed(),
                const SizedBox(height: 40),

                _buildSectionHeader('At Risk Students'),
                const SizedBox(height: 16),
                
                if (riskStudents.isEmpty)
                  _buildEmptyRiskState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: riskStudents.length,
                    itemBuilder: (context, index) {
                      final student = riskStudents[index];
                      final risk = student['risk'];
                      final riskColor = getRiskColor(risk);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            context.push('/student-detail/${student['id']}/${student['name']}');
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: riskColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: riskColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                student['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (risk == 'HIGH') ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.priority_high_rounded, color: Colors.red, size: 16),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              risk,
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: risk == 'HIGH' ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) context.push('/my-classes');
          else if (index == 2) context.push('/teacher-inbox');
          else if (index == 3) context.push('/attendance-management');
          else if (index == 4) context.push('/teacher-profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.class_rounded), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-assistant'),
        backgroundColor: const Color(0xFF1E3A8A), // Deep Blue to match professional theme
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.amber),
        label: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRiskState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade200, size: 48),
            const SizedBox(height: 12),
            const Text('All students are performing well!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            Text('Connectivity Issue', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() { _dashboardDataFuture = _apiService.fetchDashboardData(); }),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSchedule(List<dynamic> scheduleData) {
    if (scheduleData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Today\'s Schedule'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: scheduleData.asMap().entries.map<Widget>((entry) {
              int idx = entry.key;
              var s = entry.value;
              bool isLast = idx == scheduleData.length - 1;
              
              return InkWell(
                onTap: () {
                  // Navigate directly to attendance for this class/lecture
                  context.push('/lecture-attendance/${s['id']}/${s['classId']}/${Uri.encodeComponent(s['subject'])}');
                },
                child: Column(
                  children: [
                    _buildScheduleItem(s['time'], '${s['subject']} (${s['className']})', s['room']),
                    if (!isLast) const Divider(height: 24),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String title, String subtitle, {bool isFree = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFree ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: isFree ? Colors.green.shade700 : Colors.blue.shade700)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Workflows'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1, // more square shaped
          children: [
            _buildActionCard('Register\nNew Student', Icons.person_add_alt_1_rounded, Colors.blueAccent, () {
              context.push('/add-student/GLOBAL');
            }),
            _buildActionCard('Student\nDirectory', Icons.badge_rounded, Colors.teal, () {
              context.push('/global-students');
            }),
            _buildActionCard('Manage\nDivisions', Icons.layers_rounded, Colors.blue, () {
               context.push('/my-classes');
            }),
            _buildActionCard('Mark\nAttendance', Icons.how_to_reg_rounded, Colors.green, () => context.push('/attendance-management')),
            _buildActionCard('Leave\nApprovals', Icons.event_available_rounded, Colors.orange, () => context.push('/leave-approvals')),
            _buildActionCard('Student\nMessages', Icons.forum_rounded, const Color(0xFF1E3A8A), () => context.push('/teacher-inbox')),
            _buildActionCard('Digital\nLibrary', Icons.local_library_rounded, Colors.purple, () => context.push('/digital-library')),
            _buildActionCard('Timetable', Icons.table_view_rounded, Colors.indigo, () => context.push('/timetable')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Pending Tasks'),
        const SizedBox(height: 16),
        _buildTaskItem('Grade Physics Assignments', 'Class 12-B • Deadline: Today', true),
        _buildTaskItem('Submit monthly attendance report', 'Admin Dept • Overdue', false),
      ],
    );
  }

  Widget _buildTaskItem(String title, String subtitle, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: isUrgent ? Colors.redAccent : Colors.orangeAccent, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Resolve', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Announcements'),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 8),
        _buildAnnouncementCard('Staff Meeting at 4 PM', 'Admin', 'Don\'t forget the mandatory staff meeting regarding the upcoming annual sports day preparations in the main hall.'),
        _buildAnnouncementCard('New Leave Policy Updated', 'HR Dept', 'Please review the updated leave policy document available in the faculty portal.'),
      ],
    );
  }

  Widget _buildAnnouncementCard(String title, String author, String summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          Text('Posted by: $author • 2 hrs ago', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Color getRiskColor(String risk) {
    if (risk == "HIGH") return Colors.redAccent;
    if (risk == "MEDIUM") return Colors.orangeAccent;
    return Colors.greenAccent.shade700;
  }
}
