import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  String? _selectedStatus; // "Present" or "Absent"
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  late Future<Map<String, dynamic>> _attendanceFuture;
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<List<dynamic>> _insightsFuture;
  late Future<String> _riskFuture;
  late Future<List<dynamic>> _suggestionsFuture;

  // Controllers for Marks
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  bool _isMarksLoading = false;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _apiService.fetchAttendance(widget.studentId);
    _marksFuture = _apiService.fetchMarks(widget.studentId);
    _insightsFuture = _apiService.fetchInsights(widget.studentId);
    _riskFuture = _apiService.fetchRisk(widget.studentId);
    _suggestionsFuture = _apiService.fetchSuggestions(widget.studentId);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _saveMarks() async {
    final subject = _subjectController.text.trim();
    final scoreStr = _scoreController.text.trim();

    if (subject.isEmpty) {
      _showSnackBar('Please enter a subject', Colors.redAccent);
      return;
    }

    final score = int.tryParse(scoreStr);
    if (score == null || score < 0 || score > 100) {
      _showSnackBar('Please enter a valid score (0-100)', Colors.redAccent);
      return;
    }

    setState(() => _isMarksLoading = true);

    try {
      await _apiService.addMarks(widget.studentId, subject, score);
      
      if (!mounted) return;
      
      _showSnackBar('Marks recorded: $subject ($score)', Colors.green);
      
      setState(() {
        _marksFuture = _apiService.fetchMarks(widget.studentId); // Refresh history
        _insightsFuture = _apiService.fetchInsights(widget.studentId); // Refresh AI
        _riskFuture = _apiService.fetchRisk(widget.studentId); // Refresh Risk
        _suggestionsFuture = _apiService.fetchSuggestions(widget.studentId); // Refresh Suggestion
        _subjectController.clear();
        _scoreController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to save marks: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isMarksLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _saveAttendance() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select status first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.markAttendance(widget.studentId, _selectedStatus!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked for ${widget.studentName}: $_selectedStatus'),
          backgroundColor: _selectedStatus == 'Present' ? Colors.green : Colors.orange,
        ),
      );

      // Refresh attendance history after marking
      setState(() {
        _attendanceFuture = _apiService.fetchAttendance(widget.studentId);
        _insightsFuture = _apiService.fetchInsights(widget.studentId); // Refresh AI
        _riskFuture = _apiService.fetchRisk(widget.studentId); // Refresh Risk
        _suggestionsFuture = _apiService.fetchSuggestions(widget.studentId); // Refresh Suggestion
        _selectedStatus = null; // Reset selection
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard-style Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // Real-time Attendance Stats
            _buildAttendanceStats(),
            const SizedBox(height: 16),

            // GAP 8: Subject Attendance Rings
            _buildSubjectAttendanceRings(),
            const SizedBox(height: 16),
            
            // Real-time Marks Stats
            _buildMarksStats(),
            const SizedBox(height: 16),

            // Term Progress (GAP 14)
            _buildTermProgress(),

            const SizedBox(height: 16),

            // Top Subjects
            _buildTopSubjects(),
            const SizedBox(height: 16),

            // Risk Prediction Section
            _buildRiskSection(),
            const SizedBox(height: 16),

            // Smart Suggestions Section
            _buildSuggestionsSection(),
            const SizedBox(height: 32),

            // AI Insights Section
            _buildInsightsSection(),
            const SizedBox(height: 32),
            
            // AI Study Plan
            _buildStudyPlanSection(),
            const SizedBox(height: 32),

            // GAP 11: Certificate Issuing
            _buildCertificateSection(),
            const SizedBox(height: 32),

            // Interactive Selectors
            _buildMarkAttendanceSection(),
            const SizedBox(height: 32),
            _buildAddMarksSection(),
            const SizedBox(height: 32),

            // History Sections
            _buildHistorySection(),
            const SizedBox(height: 32),
            _buildMarksHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('AI Behavior Summarizer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('BETA', style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/ai-report/${widget.studentId}/${Uri.encodeComponent(widget.studentName)}');
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Full Narrative Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_rounded, color: Colors.purple.shade400, size: 28),
                  const SizedBox(width: 12),
                  const Text('Behavioral Pattern Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Overall sentiment over the past 30 days is Positive. Shows strong leadership in group exercises but occasionally gets distracted during lengthy theoretical sessions.",
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text('Engagement Trend (Last 7 Days)', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTrendBar(0.4, Colors.orange),
                  _buildTrendBar(0.6, Colors.blue),
                  _buildTrendBar(0.8, Colors.green),
                  _buildTrendBar(0.9, Colors.green),
                  _buildTrendBar(0.5, Colors.orange),
                  _buildTrendBar(0.7, Colors.blue),
                  _buildTrendBar(0.95, Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Older', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('Recent', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendBar(double heightFactor, Color color) {
    return Container(
      width: 24,
      height: 60 * heightFactor,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// GAP 14: Term Progress — mirrors student_stats_screen.dart
  Widget _buildTermProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Term Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Score trend across tests', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildProgressBar(0.60, 'Test 1'),
                _buildProgressBar(0.75, 'Test 2'),
                _buildProgressBar(0.55, 'Test 3'),
                _buildProgressBar(0.85, 'Test 4'),
                _buildProgressBar(0.70, 'Test 5'),
                _buildProgressBar(0.90, 'Test 6'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double factor, String label) {
    final color = factor >= 0.75 ? Colors.green : factor >= 0.55 ? Colors.orange : Colors.redAccent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 70 * factor,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.5), color], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  /// GAP 14: Top Subjects — mirrors student_stats_screen.dart
  Widget _buildTopSubjects() {
    final subjects = [
      {'name': 'Mathematics', 'score': 78.0, 'color': Colors.blue},
      {'name': 'Physics', 'score': 65.0, 'color': Colors.orange},
      {'name': 'Chemistry', 'score': 82.0, 'color': Colors.purple},
      {'name': 'History', 'score': 90.0, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: subjects.map((s) {
            final color = s['color'] as Color;
            final score = s['score'] as double;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  Text('${score.toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: color.withOpacity(0.1),
                      color: color,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudyPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('AI Study Roadmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('AUTO GENERATED', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade200.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Focus Subject: Mathematics",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Based on recent test scores, we recommend focusing on Calculus integration techniques for the next 2 weeks.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Timeline Steps
              _buildRoadmapStep("Week 1", "Review basic integration formulas and solve 20 practice questions.", true),
              _buildRoadmapStep("Week 2", "Move to Definite Integrals and Area under curves.", false),
              _buildRoadmapStep("Week 3", "Take a mock test on integration.", false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapStep(String week, String description, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.amber : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: isCurrent ? const Icon(Icons.star, size: 14, color: Colors.white) : const SizedBox(),
              ),
              Container(
                width: 2,
                height: 30,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(week, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.amber.shade800 : Colors.black87)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// GAP 11: Certificate issuance
  Widget _buildCertificateSection() {
    final templates = [
      {'label': 'Merit Certificate', 'icon': Icons.emoji_events_rounded, 'color': Colors.amber},
      {'label': 'Participation', 'icon': Icons.star_rounded, 'color': Colors.blue},
      {'label': 'Excellence Award', 'icon': Icons.workspace_premium_rounded, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Issue Certificate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('OFFICIAL', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: templates.map((t) {
            final color = t['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => _showCertificateSheet(t['label'] as String, t['icon'] as IconData, color),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    border: Border.all(color: color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(t['icon'] as IconData, color: color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        t['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCertificateSheet(String type, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        bool issued = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: color, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        type,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Awarded to: ${widget.studentName}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued by: Classlytics  •  ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (issued)
                  Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      const Text('Certificate issued successfully!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 800));
                      setSheetState(() => issued = true);
                    },
                    icon: Icon(icon, size: 18),
                    label: const Text('Issue Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddMarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Marks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Mathematics',
                  prefixIcon: const Icon(Icons.book_rounded, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Score',
                  hintText: '0-100',
                  prefixIcon: const Icon(Icons.numbers_rounded, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveMarks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isMarksLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarksStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _marksFuture,
      builder: (context, snapshot) {
        String average = "--";
        if (snapshot.hasData) {
          average = "${snapshot.data!['average']}";
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Average Score', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('Academic Performance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                average,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.orange),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarksHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Academic Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _marksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            
            final history = snapshot.data?['marks'] as List? ?? [];
            if (history.isEmpty) return const Text('No academic records found', style: TextStyle(color: Colors.grey));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[history.length - 1 - index]; // Latest first
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record['subject'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            Text(record['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${record['score']}/100',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blueAccent.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            widget.studentName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text('ID: ${widget.studentId}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          // GAP 6: Fee Status Badge
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildHeaderBadge(Icons.check_circle_rounded, 'Fees Paid', Colors.greenAccent.shade700),
              _buildHeaderBadge(Icons.class_rounded, 'Class 10 A', Colors.white70),
              _buildHeaderBadge(Icons.calendar_today_rounded, 'Yr 2026', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        String percentage = "--";
        if (snapshot.hasData) {
          percentage = "${snapshot.data!['percentage']}%";
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('Overall Performance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blueAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatusOption('Present', Icons.check_circle_rounded, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatusOption('Absent', Icons.cancel_rounded, Colors.redAccent),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// GAP 8: Subject-wise attendance rings
  Widget _buildSubjectAttendanceRings() {
    final subjects = [
      {'sub': 'Math', 'pct': 0.92, 'color': Colors.blue},
      {'sub': 'Physics', 'pct': 0.74, 'color': Colors.orange},
      {'sub': 'Chemistry', 'pct': 0.85, 'color': Colors.purple},
      {'sub': 'History', 'pct': 0.60, 'color': Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Per-subject breakdown', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 16,
            children: subjects.map((s) {
              final pct = s['pct'] as double;
              final color = s['color'] as Color;
              final isLow = pct < 0.75;
              return Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 7,
                          backgroundColor: color.withOpacity(0.12),
                          color: color,
                        ),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isLow ? Colors.red : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s['sub'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                  if (isLow) ...[const SizedBox(height: 2), const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red)],
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attendance History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            
            final history = snapshot.data?['attendance'] as List? ?? [];
            if (history.isEmpty) return const Text('No records found', style: TextStyle(color: Colors.grey));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[history.length - 1 - index];
                final status = record['status'];
                final isPresent = status == 'Present';
                final color = isPresent ? Colors.green : Colors.redAccent;

                // GAP 9: Tappable heatmap tile
                return GestureDetector(
                  onTap: () => _showAttendanceDetail(record),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(record['date'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAttendanceDetail(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final isPresent = status == 'Present';
    final color = isPresent ? Colors.green : Colors.redAccent;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
                    Text(record['date'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.person_rounded, 'Student', widget.studentName),
            _detailRow(Icons.confirmation_number_rounded, 'Student ID', widget.studentId),
            _detailRow(Icons.class_rounded, 'Class', 'Class 10 A'),
            _detailRow(Icons.access_time_rounded, 'Recorded At', '08:45 AM'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status, IconData icon, Color color) {
    bool isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                status,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _suggestionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            
            final suggestions = snapshot.data ?? [];
            if (suggestions.isEmpty) return const Text('No suggestions available', style: TextStyle(color: Colors.grey));

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: Column(
                children: suggestions.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRiskSection() {
    return FutureBuilder<String>(
      future: _riskFuture,
      builder: (context, snapshot) {
        String risk = "LOADING";
        Color color = Colors.grey;

        if (snapshot.hasData) {
          risk = snapshot.data!;
          if (risk == "HIGH") color = Colors.redAccent;
          else if (risk == "MEDIUM") color = Colors.orangeAccent;
          else color = Colors.greenAccent.shade700;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              const Text(
                'Student Risk Level',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                risk,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
