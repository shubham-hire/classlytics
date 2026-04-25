import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminManageClassesScreen extends StatefulWidget {
  final int? deptId;
  final String? deptName;
  const DeptAdminManageClassesScreen({super.key, this.deptId, this.deptName});
  @override
  State<DeptAdminManageClassesScreen> createState() => _DeptAdminManageClassesScreenState();
}

class _DeptAdminManageClassesScreenState extends State<DeptAdminManageClassesScreen> {
  final _api = ApiService();
  List<dynamic> _classes = [];
  List<dynamic> _departments = [];
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  int? _selectedDeptId;
  bool _creating = false;

  static const _blue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _selectedDeptId = widget.deptId;
    _loadDepts().then((_) => _load());
  }

  Future<void> _loadDepts() async {
    try { _departments = await _api.deptAdminGetDepartments(); } catch (_) {}
    if (_selectedDeptId == null && _departments.isNotEmpty) {
      _selectedDeptId = _departments.first['id'] as int;
    }
  }

  Future<void> _load() async {
    if (_selectedDeptId == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    try { _classes = await _api.deptAdminGetClasses(_selectedDeptId!); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _createClass() async {
    if (_nameCtrl.text.trim().isEmpty || _sectionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and section are required'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _creating = true);
    try {
      await _api.deptAdminCreateClass(
        name: _nameCtrl.text.trim(),
        section: _sectionCtrl.text.trim(),
        departmentId: _selectedDeptId,
      );
      _nameCtrl.clear(); _sectionCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class created!'), backgroundColor: Colors.green));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
        title: const Text('Manage Classes', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/dept-admin/department')),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_departments.length > 1) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedDeptId,
                    decoration: InputDecoration(
                      labelText: 'Department', prefixIcon: const Icon(Icons.domain_rounded),
                      filled: true, fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _departments.map<DropdownMenuItem<int>>((d) =>
                      DropdownMenuItem(value: d['id'] as int, child: Text(d['name']))).toList(),
                    onChanged: (v) { setState(() => _selectedDeptId = v); _load(); },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(child: TextField(controller: _nameCtrl,
                    decoration: InputDecoration(hintText: 'Class name (e.g. FY-BSc)',
                      filled: true, fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  )),
                  const SizedBox(width: 8),
                  SizedBox(width: 90, child: TextField(controller: _sectionCtrl,
                    decoration: InputDecoration(hintText: 'Section',
                      filled: true, fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  )),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _creating ? null : _createClass,
                    style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _creating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add'),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _classes.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No classes yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _classes.length,
                        itemBuilder: (ctx, i) {
                          final c = _classes[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _blue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.class_rounded, color: _blue),
                              ),
                              title: Text('${c['name']} — ${c['section']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${c['division_count'] ?? 0} divisions  •  Teacher: ${c['teacher_name'] ?? 'Unassigned'}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: _blue),
                                onPressed: () => context.go('/dept-admin/divisions?classId=${c['id']}&className=${Uri.encodeComponent('${c['name']} ${c['section']}')}'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
