import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/teacher_admin.dart';

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
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Teacher Management', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTeachers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/teachers/add'),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Teacher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintStyle: const TextStyle(color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTeachers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildTeacherCard(filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(TeacherAdmin teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE2E8F0),
          backgroundImage: teacher.profileImg != null && teacher.profileImg!.isNotEmpty
              ? NetworkImage('${ApiService.baseUrl}/uploads/${teacher.profileImg}')
              : null,
          child: teacher.profileImg == null || teacher.profileImg!.isEmpty
              ? Text(teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 20))
              : null,
        ),
        title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${teacher.designation} • ${teacher.employeeId}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(teacher.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
              onPressed: () => context.go('/admin/teachers/edit/${teacher.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _deleteTeacher(teacher.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No teachers found', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
