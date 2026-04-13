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
            
            // Real-time Marks Stats
            _buildMarksStats(),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average Score', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text('Academic Performance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(record['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text('Overall Performance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
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
                final record = history[history.length - 1 - index]; // Show latest first
                final status = record['status'];
                final isPresent = status == 'Present';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(record['date'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPresent ? Colors.green : Colors.redAccent).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
