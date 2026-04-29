import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminStudentsScreen extends StatefulWidget {
  final int? divisionId;
  final String? divisionName;
  const DeptAdminStudentsScreen({super.key, this.divisionId, this.divisionName});

  @override
  State<DeptAdminStudentsScreen> createState() => _DeptAdminStudentsScreenState();
}

class _DeptAdminStudentsScreenState extends State<DeptAdminStudentsScreen> {
  final _api = ApiService();
  List<dynamic> _students = [];
  bool _loading = true;
  bool _showForm = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _saving = false;

  static const _orange = Color(0xFFE64A19);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (widget.divisionId != null) {
        _students = await _api.deptAdminGetStudents(widget.divisionId!);
      } else {
        // Global view: fetch all students in the department
        _students = await _api.deptAdminGetStudentsByYear();
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _addStudent() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email are required'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _api.deptAdminAddStudent(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        divisionId: widget.divisionId!,
        rollNo: _rollCtrl.text.trim().isNotEmpty ? _rollCtrl.text.trim() : null,
        currentYear: _yearCtrl.text.trim().isNotEmpty ? _yearCtrl.text.trim() : '1st Year',
      );
      if (mounted) {
        _nameCtrl.clear(); _emailCtrl.clear(); _rollCtrl.clear(); _yearCtrl.clear();
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student added! Temp password: ${result['tempPassword'] ?? 'N/A'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Students', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (widget.divisionName != null)
              Text(widget.divisionName!, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dept-admin/academic-hub?tab=1'),
        ),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close_rounded : Icons.person_add_rounded),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add student form
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showForm
                ? Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add New Student',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 12),
                        _field(_nameCtrl, 'Full Name', Icons.person_rounded),
                        const SizedBox(height: 10),
                        _field(_emailCtrl, 'Email Address', Icons.email_rounded,
                            type: TextInputType.emailAddress),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _field(_rollCtrl, 'Roll No (optional)', Icons.tag_rounded,
                              type: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(_yearCtrl, 'Year (e.g. 1st Year)', Icons.school_rounded)),
                        ]),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _addStudent,
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Add Student', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Students list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No students in this division', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => setState(() => _showForm = true),
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Add Student'),
                            style: FilledButton.styleFrom(backgroundColor: _orange),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: _orange.withOpacity(0.12),
                                  child: Text(
                                    (s['name'] as String? ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(color: _orange, fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ),
                                title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  '${s['email'] ?? ''}  •  Roll: ${s['roll_no'] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(s['current_year'] ?? '', style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
