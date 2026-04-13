import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import 'detailed_analytics_screen.dart';

class StudentStatsScreen extends StatefulWidget {
  const StudentStatsScreen({super.key});

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<String> _riskFuture;

  String get _studentId => AuthStore.instance.studentId;

  @override
  void initState() {
    super.initState();
    _marksFuture = _apiService.fetchMarks(_studentId);
    _riskFuture = _apiService.fetchRisk(_studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // AI Prediction Card
              _buildRiskPredictionCard(),
              const SizedBox(height: 32),

              // Term Progress Graph
              const Text(
                'Term Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMockBar(60),
                    _buildMockBar(80),
                    _buildMockBar(45),
                    _buildMockBar(90),
                    _buildMockBar(70),
                    _buildMockBar(85),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subject Scores
              const Text(
                'Top Subjects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSubjectCard('Math', '78%', Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSubjectCard('Physics', '65%', Colors.orange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSubjectCard('Chemistry', '82%', Colors.purple)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSubjectCard('History', '90%', Colors.green)),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskPredictionCard() {
    return FutureBuilder(
      future: Future.wait([_marksFuture, _riskFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        String score = "--%";
        String risk = "Analyzing...";
        Color riskColor = Colors.grey;

        if (snapshot.hasData) {
          final marksData = snapshot.data![0] as Map<String, dynamic>;
          score = '${marksData['average']}%';
          risk = snapshot.data![1] as String;
          
          if (risk == 'HIGH') riskColor = Colors.red;
          else if (risk == 'MEDIUM') riskColor = Colors.orange;
          else riskColor = Colors.green;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: risk == 'HIGH' 
                ? [Colors.red.shade400, Colors.red.shade700]
                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (risk == 'HIGH' ? Colors.red : const Color(0xFF6366F1)).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailedAnalyticsScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text('Core Academic Health', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Avg Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(score, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Risk: $risk', 
                            style: TextStyle(color: riskColor, fontWeight: FontWeight.w900, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockBar(double heightFactor) {
    return Container(
      width: 32,
      height: 150 * (heightFactor / 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withOpacity(0.5), AppTheme.accentColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildSubjectCard(String title, String score, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(score, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
    const SizedBox(height: 8),
          LinearProgressIndicator(
            value: double.parse(score.replaceAll('%', '')) / 100,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
