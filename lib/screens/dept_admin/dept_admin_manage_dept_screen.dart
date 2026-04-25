import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminManageDeptScreen extends StatefulWidget {
  const DeptAdminManageDeptScreen({super.key});
  @override
  State<DeptAdminManageDeptScreen> createState() => _DeptAdminManageDeptScreenState();
}

class _DeptAdminManageDeptScreenState extends State<DeptAdminManageDeptScreen> {
  final _api = ApiService();
  List<dynamic> _departments = [];
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  bool _creating = false;

  static const _teal = Color(0xFF0F9D8C);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _departments = await _api.deptAdminGetDepartments(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _createDept() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      await _api.deptAdminCreateDepartment(name);
      _nameCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department created!'), backgroundColor: Colors.green));
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
        backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
        title: const Text('Manage Departments', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/dept-admin')),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Department name (e.g. Computer Science)',
                      prefixIcon: const Icon(Icons.domain_rounded),
                      filled: true, fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _creating ? null : _createDept,
                  style: FilledButton.styleFrom(backgroundColor: _teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _creating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _departments.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.domain_disabled_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No departments yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _departments.length,
                        itemBuilder: (ctx, i) {
                          final d = _departments[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _teal.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.domain_rounded, color: _teal),
                              ),
                              title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              subtitle: Text('ID: ${d['id']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              trailing: FilledButton.tonal(
                                onPressed: () => context.go('/dept-admin/classes?deptId=${d['id']}&deptName=${Uri.encodeComponent(d['name'])}'),
                                style: FilledButton.styleFrom(backgroundColor: _teal.withOpacity(0.12), foregroundColor: _teal),
                                child: const Text('View Classes'),
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
