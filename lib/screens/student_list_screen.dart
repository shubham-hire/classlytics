import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'global_student_selection_screen.dart';

class StudentListScreen extends StatefulWidget {
  final String classId;

  const StudentListScreen({super.key, required this.classId});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late Future<List<dynamic>> _studentsFuture;
  final ApiService _apiService = ApiService();
  
  List<dynamic>? _allStudents;
  List<dynamic>? _filteredStudents;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentsFuture = _apiService.fetchStudents(widget.classId);
  }

  void _filterStudents(String query) {
    if (_allStudents == null) return;
    
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents!
            .where((student) => 
                student['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Students',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/class-report/${widget.classId}/General'),
            tooltip: 'Class Report',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_rounded),
            onPressed: () => context.push('/assignments/${widget.classId}'),
            tooltip: 'Assignments',
          ),
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            onPressed: () => _showGlobalSelection(),
            tooltip: 'Add from Registered Students',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () => _showBulkAddDialog(),
            tooltip: 'Bulk Add Students',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students found', style: TextStyle(color: Colors.grey)));
          }

          // Initialize local lists once data is loaded
          if (_allStudents == null) {
            _allStudents = snapshot.data;
            _filteredStudents = _allStudents;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterStudents,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Class ID: ${widget.classId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _filteredStudents!.isEmpty 
                  ? const Center(child: Text('No matching students found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredStudents!.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents![index];
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
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              child: Text(
                                student['name'][0],
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              'Roll No: ${student['roll_no'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                              onPressed: () => _showUpdateStudentDialog(student),
                            ),
                            onTap: () {
                              context.push('/student-detail/${student['id']}/${student['name']}');
                            },
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            const Text('Failed to load students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _allStudents = null;
                  _filteredStudents = null;
                  _searchController.clear();
                  _studentsFuture = _apiService.fetchStudents(widget.classId);
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStudentDialog(dynamic student) {
    final nameController = TextEditingController(text: student['name']);
    final rollController = TextEditingController(text: student['roll_no']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: rollController, decoration: const InputDecoration(labelText: 'Roll Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _apiService.updateStudent(student['id'], nameController.text, rollController.text, widget.classId);
                nav.pop();
                setState(() { _studentsFuture = _apiService.fetchStudents(widget.classId); _allStudents = null; });
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showBulkAddDialog() {
    final bulkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Add Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter list in format:\nName, Email, RollNo (one per line)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: bulkController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Rahul, rahul@email.com, 01\nSneha, sneha@email.com, 02',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                List<String> lines = bulkController.text.split('\n');
                List<Map<String, String>> studentList = [];
                for (var line in lines) {
                  var parts = line.split(',');
                  if (parts.length >= 2) {
                    studentList.add({
                      'name': parts[0].trim(),
                      'email': parts[1].trim(),
                      'rollNo': parts.length > 2 ? parts[2].trim() : '',
                    });
                  }
                }
                if (studentList.isNotEmpty) {
                  await _apiService.bulkAddStudents(widget.classId, studentList);
                  nav.pop();
                  setState(() { _studentsFuture = _apiService.fetchStudents(widget.classId); _allStudents = null; });
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add All'),
          ),
        ],
      ),
    );
  }

  void _showGlobalSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalStudentSelectionScreen(
          classId: widget.classId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _studentsFuture = _apiService.fetchStudents(widget.classId);
          _allStudents = null;
        });
      }
    });
  }
}
