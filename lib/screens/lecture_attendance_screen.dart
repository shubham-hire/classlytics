import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LectureAttendanceScreen extends StatefulWidget {
  final String lectureId;
  final String classId;

  const LectureAttendanceScreen({super.key, required this.lectureId, required this.classId});

  @override
  State<LectureAttendanceScreen> createState() => _LectureAttendanceScreenState();
}

class _LectureAttendanceScreenState extends State<LectureAttendanceScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _studentsFuture;
  
  // Mapping student ID to their attendance status (true = Present, false = Absent)
  final Map<String, bool> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() {
    _studentsFuture = _apiService.fetchStudents(widget.classId);
    _studentsFuture.then((students) {
      if (mounted) {
        setState(() {
          for (var student in students) {
            // Default everyone to present to save teacher's time
            _attendanceMap[student['id']] = true;
          }
        });
      }
    });
  }

  void _submitAttendance() async {
    int successCount = 0;
    try {
      // In a real app we'd bulk-submit. Here we loop due to existing single-student endpoint
      for (var entry in _attendanceMap.entries) {
        final studentId = entry.key;
        final status = entry.value ? 'Present' : 'Absent';
        
        await _apiService.markAttendance(studentId, status);
        successCount++;
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance recorded for $successCount students!'), backgroundColor: Colors.green));
      Navigator.pop(context); // Go back to dashboard after saving
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to record attendance: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitAttendance,
            child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
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
            return const Center(child: Text('No students found.', style: TextStyle(color: Colors.grey)));
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.white,
                width: double.infinity,
                child: Text(
                  'Lecture ID: ${widget.lectureId} • Class: ${widget.classId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final studentId = student['id'];
                    final isPresent = _attendanceMap[studentId] ?? true;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Roll No: ${student['roll']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _attendanceMap[studentId] = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green : Colors.grey.shade200,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                ),
                                child: Text('P', style: TextStyle(color: isPresent ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _attendanceMap[studentId] = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isPresent ? Colors.redAccent : Colors.grey.shade200,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                ),
                                child: Text('A', style: TextStyle(color: !isPresent ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
