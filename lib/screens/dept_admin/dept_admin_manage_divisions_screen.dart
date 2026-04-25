import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminManageDivisionsScreen extends StatefulWidget {
  final String? classId;
  final String? className;
  const DeptAdminManageDivisionsScreen({super.key, this.classId, this.className});

  @override
  State<DeptAdminManageDivisionsScreen> createState() =>
      _DeptAdminManageDivisionsScreenState();
}

class _DeptAdminManageDivisionsScreenState
    extends State<DeptAdminManageDivisionsScreen> {
  final _api = ApiService();
  List<dynamic> _divisions = [];
  bool _loading = true;
  final _divCtrl = TextEditingController();
  bool _creating = false;

  static const _purple = Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.classId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      _divisions = await _api.deptAdminGetDivisions(widget.classId!);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final name = _divCtrl.text.trim();
    if (name.isEmpty || widget.classId == null) return;
    setState(() => _creating = true);
    try {
      await _api.deptAdminCreateDivision(
        classId: widget.classId!,
        divisionName: name,
      );
      _divCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Division created!'),
              backgroundColor: Colors.green),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Divisions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (widget.className != null)
              Text(widget.className!,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dept-admin/classes'),
        ),
      ),
      body: Column(
        children: [
          // Create bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _divCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Division name (e.g. A, B, C)',
                      prefixIcon: const Icon(Icons.account_tree_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _creating ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _divisions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_tree_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No divisions yet',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _divisions.length,
                        itemBuilder: (ctx, i) {
                          final div = _divisions[i];
                          final count = div['student_count'] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8)
                              ],
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    _purple.withOpacity(0.12),
                                child: Text(
                                  div['division_name'] ?? '',
                                  style: const TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18),
                                ),
                              ),
                              title: Text(
                                'Division ${div['division_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                              subtitle: Text('$count student${count != 1 ? 's' : ''}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => context.go(
                                        '/dept-admin/students?divisionId=${div['id']}&divisionName=${Uri.encodeComponent('Division ${div['division_name']}')}'),
                                    icon: const Icon(Icons.people_alt_rounded,
                                        size: 16),
                                    label: const Text('Students'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _purple,
                                      side:
                                          const BorderSide(color: _purple),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
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
      ),
    );
  }
}
