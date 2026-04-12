import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
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
      backgroundColor: const Color(0xFFF8F9FA), // Subtle professional background
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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

  Color getRiskColor(String risk) {
    if (risk == "HIGH") return Colors.redAccent;
    if (risk == "MEDIUM") return Colors.orangeAccent;
    return Colors.greenAccent.shade700;
  }
}
