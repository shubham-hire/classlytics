import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/teacher_admin.dart';
import '../admin_shell.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<TeacherAdmin> _teachers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.fetchTeachers();
      setState(() {
        _teachers = data.map((e) => TeacherAdmin.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTeacher(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Teacher?'),
        content: const Text('This will permanently delete the teacher and their user account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteTeacher(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher deleted successfully'), backgroundColor: Colors.green));
        _loadTeachers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) {
      final q = _searchQuery.toLowerCase();
      return t.name.toLowerCase().contains(q) || t.email.toLowerCase().contains(q) || t.employeeId.toLowerCase().contains(q);
    }).toList();

    return AdminShell(
      title: 'Teacher Management',
      child: Column(
        children: [
          // ─── CONTROL BAR ───
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or employee ID...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/teachers/add'),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ─── DATA CONTENT ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return _buildTeacherTable(filtered);
                      } else {
                        return _buildTeacherList(filtered);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherTable(List<TeacherAdmin> filtered) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowHeight: 80,
          columns: const [
            DataColumn(label: Text('TEACHER', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DESIGNATION', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('EMPLOYEE ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((teacher) {
            return DataRow(cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: teacher.profileImg != null && teacher.profileImg!.isNotEmpty
                          ? NetworkImage('${ApiService.baseUrl}/uploads/${teacher.profileImg}')
                          : null,
                      child: teacher.profileImg == null || teacher.profileImg!.isEmpty
                          ? Text(teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?', 
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(teacher.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(teacher.designation)),
              DataCell(Text(teacher.employeeId)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                      onPressed: () => context.push('/admin/teachers/edit/${teacher.id}').then((_) => _loadTeachers()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteTeacher(teacher.id),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherList(List<TeacherAdmin> filtered) {
    if (filtered.isEmpty) {
      return const Center(child: Text('No teachers found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final teacher = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: teacher.profileImg != null && teacher.profileImg!.isNotEmpty
                  ? NetworkImage('${ApiService.baseUrl}/uploads/${teacher.profileImg}')
                  : null,
              child: teacher.profileImg == null || teacher.profileImg!.isEmpty
                  ? Text(teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?')
                  : null,
            ),
            title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(teacher.designation),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/admin/teachers/edit/${teacher.id}'),
          ),
        );
      },
    );
  }
}
