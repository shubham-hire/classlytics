import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminCreateClassScreen extends StatefulWidget {
  const DeptAdminCreateClassScreen({super.key});
  @override
  State<DeptAdminCreateClassScreen> createState() => _DeptAdminCreateClassScreenState();
}

class _DeptAdminCreateClassScreenState extends State<DeptAdminCreateClassScreen> {
  final _api = ApiService();
  int _step = 0; // 0=form, 1=review, 2=roll numbers

  // Form fields
  String _selectedYear = '1st Year';
  String _selectedDivision = 'A';
  String? _selectedTeacherId;

  // Data
  List<dynamic> _teachers = [];
  List<dynamic> _availableStudents = [];
  final Set<String> _selectedStudentIds = {};
  bool _loadingTeachers = true;
  bool _loadingStudents = false;
  bool _creating = false;

  // Result after creation
  Map<String, dynamic>? _creationResult;
  List<dynamic>? _rollAssignments;
  bool _assigningRolls = false;

  static const _teal = Color(0xFF0F9D8C);
  static const _blue = Color(0xFF1976D2);
  static const _purple = Color(0xFF7B1FA2);

  final _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final _divisions = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      _teachers = await _api.deptAdminGetTeachers();
    } catch (_) {}
    setState(() => _loadingTeachers = false);
  }

  Future<void> _loadStudentsByYear() async {
    setState(() => _loadingStudents = true);
    try {
      _availableStudents = await _api.deptAdminGetStudentsByYear(year: _selectedYear);
    } catch (_) {
      _availableStudents = [];
    }
    setState(() => _loadingStudents = false);
  }

  Future<void> _createClass() async {
    setState(() => _creating = true);
    try {
      final result = await _api.deptAdminCreateClassEnhanced(
        name: _selectedYear,
        year: _selectedYear,
        division: _selectedDivision,
        teacherId: _selectedTeacherId,
        studentIds: _selectedStudentIds.toList(),
      );
      _creationResult = result;
      setState(() => _step = 2);
      _showSnack('Class created successfully!', Colors.green);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
    setState(() => _creating = false);
  }

  Future<void> _autoAssignRolls() async {
    if (_creationResult == null) return;
    setState(() => _assigningRolls = true);
    try {
      final classId = _creationResult!['classId'];
      final divId = _creationResult!['divisionId'];
      final result = await _api.deptAdminAssignRollNumbers(
        classId: classId,
        divisionId: divId is int ? divId : int.tryParse(divId.toString()),
      );
      _rollAssignments = result['assignments'] as List<dynamic>?;
      _showSnack('Roll numbers assigned to ${result['total']} students!', Colors.green);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
    setState(() => _assigningRolls = false);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create Class', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dept-admin'),
        ),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: _step == 0
                ? _buildFormStep()
                : _step == 1
                    ? _buildReviewStep()
                    : _buildRollNumberStep(),
          ),
        ],
      ),
    );
  }

  // ─── STEPPER INDICATOR ───
  Widget _buildStepper() {
    final steps = ['Class Details', 'Select Students', 'Roll Numbers'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.white,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? _blue : Colors.grey.shade300,
                    ),
                  ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? _blue : isActive ? _blue : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : Text('${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? _blue : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── STEP 1: CLASS DETAILS FORM ───
  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Class Information'),
          const SizedBox(height: 12),
          _card([
            _dropdownField<String>(
              'Year', _selectedYear, _years,
              Icons.calendar_today_rounded,
              (v) => setState(() => _selectedYear = v!),
            ),
            const SizedBox(height: 14),
            _dropdownField<String>(
              'Division', _selectedDivision, _divisions,
              Icons.account_tree_rounded,
              (v) => setState(() => _selectedDivision = v!),
            ),
            const SizedBox(height: 14),
            _loadingTeachers
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: _inputDeco('Class Teacher (Optional)', Icons.person_rounded),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— No Teacher —')),
                      ..._teachers.map((t) => DropdownMenuItem(
                            value: t['id'] as String,
                            child: Text(t['name'] ?? t['email'] ?? ''),
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedTeacherId = v),
                  ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next: Select Students', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _loadStudentsByYear();
                setState(() => _step = 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: SELECT STUDENTS ───
  Widget _buildReviewStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded, color: _blue, size: 20),
              const SizedBox(width: 8),
              Text('Students for $_selectedYear',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_selectedStudentIds.length} selected',
                    style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
        if (_selectedStudentIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _blue.withOpacity(0.05),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.deselect_rounded, size: 18),
                  label: const Text('Clear All'),
                  onPressed: () => setState(() => _selectedStudentIds.clear()),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.select_all_rounded, size: 18),
                  label: const Text('Select All'),
                  onPressed: () => setState(() {
                    for (final s in _availableStudents) {
                      _selectedStudentIds.add(s['student_id'] as String);
                    }
                  }),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _availableStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No students found for $_selectedYear',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _availableStudents.length,
                      itemBuilder: (_, i) {
                        final s = _availableStudents[i];
                        final sid = s['student_id'] as String;
                        final isSelected = _selectedStudentIds.contains(sid);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? _blue.withOpacity(0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _blue.withOpacity(0.3) : Colors.grey.shade200,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: _blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('${s['email'] ?? ''} • ${s['current_year'] ?? ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            secondary: CircleAvatar(
                              backgroundColor: isSelected ? _blue : Colors.grey.shade200,
                              child: Text(
                                (s['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedStudentIds.add(sid);
                                } else {
                                  _selectedStudentIds.remove(sid);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _step = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: _creating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_creating ? 'Creating...' : 'Create Class',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _creating ? null : _createClass,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: ROLL NUMBERS ───
  Widget _buildRollNumberStep() {
    return Column(
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F9D8C), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Created!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      '${_creationResult?['name']} • ${_creationResult?['section']} • ${_creationResult?['students_assigned'] ?? 0} students',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Auto-assign button
        if (_rollAssignments == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: _assigningRolls
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.format_list_numbered_rounded),
                label: Text(
                  _assigningRolls ? 'Assigning...' : 'Auto Assign Roll Numbers',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _assigningRolls ? null : _autoAssignRolls,
              ),
            ),
          ),
        // Roll number list
        if (_rollAssignments != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, color: _purple, size: 20),
                const SizedBox(width: 8),
                Text('Roll Numbers Assigned (${_rollAssignments!.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _rollAssignments!.length,
              itemBuilder: (_, i) {
                final r = _rollAssignments![i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('${r['roll_no']}',
                              style: TextStyle(color: _purple, fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(r['student_id'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 22),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else
          const Spacer(),
        // Done button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Done — Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.go('/dept-admin'),
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ───
  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B)));

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, String hint) =>
      TextField(controller: ctrl, decoration: _inputDeco(label, icon).copyWith(hintText: hint));

  Widget _dropdownField<T>(String label, T value, List<T> items, IconData icon, ValueChanged<T?> onChanged) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: _inputDeco(label, icon),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
        onChanged: onChanged,
      );
}
