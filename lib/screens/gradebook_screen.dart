import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class GradebookScreen extends StatefulWidget {
  final String classId;

  const GradebookScreen({super.key, required this.classId});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _studentsFuture;
  
  String? _selectedSubject;
  String _selectedExamType = 'Mid Sem';
  
  final List<String> _examTypes = ['Mid Sem', 'Oral', 'Internal', 'End Sem'];
  final List<String> _subjects = ['Software Engineering', 'Database Management', 'Computer Networks', 'AI & ML'];

  // Storing simple string marks for demo: { studentId: text }
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedSubject = _subjects[0];
    _fetchStudents();
  }

  void _fetchStudents() {
    _studentsFuture = _apiService.fetchStudents(widget.classId);
    _studentsFuture.then((students) {
      for (var student in students) {
        if (!_scoreControllers.containsKey(student['id'])) {
          _scoreControllers[student['id']] = TextEditingController();
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveGrades() async {
    int savedCount = 0;
    try {
      for (var entry in _scoreControllers.entries) {
        String studentId = entry.key;
        String scoreStr = entry.value.text.trim();
        
        if (scoreStr.isNotEmpty) {
          int? score = int.tryParse(scoreStr);
          if (score != null) {
            // Use selected exam type as subject/category
            await _apiService.addMarks(studentId, '$_selectedSubject - $_selectedExamType', score);
            savedCount++;
          }
        }
      }
      
      if (!mounted) return;
      if (savedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully saved $savedCount grades!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new grades to save')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save grades: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Academic Gradebook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_rounded),
            onPressed: () {
              context.push('/class-report/${widget.classId}/${Uri.encodeComponent(_selectedSubject ?? "General")}');
            },
            tooltip: 'View Class Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubject,
                            isExpanded: true,
                            items: _subjects.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSubject = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exam Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedExamType,
                            isExpanded: true,
                            items: _examTypes.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedExamType = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<dynamic>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(child: Text('No students found.', style: TextStyle(color: Colors.grey, fontSize: 16)));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.blueGrey.shade50),
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: students.map((student) {
                      return DataRow(
                        cells: [
                          DataCell(Text(student['roll'].toString())),
                          DataCell(Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextField(
                                controller: _scoreControllers[student['id']],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '-',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: _saveGrades,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Update & Save Marks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
