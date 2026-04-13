import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GlobalStudentSelectionScreen extends StatefulWidget {
  final String? deptFilter;
  final String? yearFilter;
  final String? classId; // If provided, will enroll selected students to this class

  const GlobalStudentSelectionScreen({
    super.key, 
    this.deptFilter, 
    this.yearFilter,
    this.classId,
  });

  @override
  State<GlobalStudentSelectionScreen> createState() => _GlobalStudentSelectionScreenState();
}

class _GlobalStudentSelectionScreenState extends State<GlobalStudentSelectionScreen> {
  late Future<List<dynamic>> _studentsFuture;
  final ApiService _apiService = ApiService();
  final Set<String> _selectedIds = {};
  bool _isEnrolling = false;

  String? _filterDept;
  String? _filterYear;

  final List<String> _departments = ['All', 'Computer Science', 'Information Technology', 'Mechanical Engineering', 'Electronics & TC', 'Civil Engineering', 'Applied Sciences'];
  final List<String> _academicYears = ['All', 'First Year', 'Second Year', 'Third Year', 'Final Year'];

  @override
  void initState() {
    super.initState();
    _refreshStudents();
  }

  void _refreshStudents() {
    setState(() {
      _studentsFuture = _apiService.fetchRegisteredStudents(
        dept: (_filterDept == null || _filterDept == 'All') ? null : _filterDept,
        year: (_filterYear == null || _filterYear == 'All') ? null : _filterYear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.classId != null ? 'Select Students for Division' : 'Registered Students',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No registered students found matching criteria.'));
          }

          final students = snapshot.data!;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterDept ?? 'All',
                        decoration: const InputDecoration(labelText: 'Dept', border: OutlineInputBorder()),
                        items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) { _filterDept = val; _refreshStudents(); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterYear ?? 'All',
                        decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                        items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) { _filterYear = val; _refreshStudents(); },
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  width: double.infinity,
                  child: Text(
                    '${_selectedIds.length} students selected',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final isSelected = _selectedIds.contains(s['id']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(s['id']);
                            } else {
                              _selectedIds.remove(s['id']);
                            }
                          });
                        },
                        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s['id']} • ${s['dept']} • ${s['current_year']}'),
                        secondary: CircleAvatar(
                          child: Text(s['name'][0]),
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
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isEnrolling ? null : _handleEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isEnrolling
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.classId != null 
                          ? 'Add ${_selectedIds.length} Students to Division' 
                          : 'Action on ${_selectedIds.length} Selected',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
    );
  }

  Future<void> _handleEnrollment() async {
    if (widget.classId == null) return;

    setState(() => _isEnrolling = true);
    try {
      await _apiService.enrollStudents(widget.classId!, _selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully enrolled ${_selectedIds.length} students!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }
}
