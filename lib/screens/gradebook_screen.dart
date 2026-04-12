import 'package:flutter/material.dart';
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

  // Storing simple string marks for demo: { studentId: text }
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
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
            // Hardcode 'Midterm' as the subject for this advanced gradebook demo
            await _apiService.addMarks(studentId, 'Midterm', score);
            savedCount++;
            entry.value.clear(); // Clear after saving
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
        title: const Text('Advanced Gradebook', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveGrades,
            icon: const Icon(Icons.save, color: Colors.blueAccent),
            label: const Text('Save All', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
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
                      DataColumn(label: Text('Midterm Grade', style: TextStyle(fontWeight: FontWeight.bold))),
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
    );
  }
}
