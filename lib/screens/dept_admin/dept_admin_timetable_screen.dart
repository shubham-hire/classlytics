import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminTimetableScreen extends StatefulWidget {
  const DeptAdminTimetableScreen({super.key});

  @override
  State<DeptAdminTimetableScreen> createState() => _DeptAdminTimetableScreenState();
}

class _DeptAdminTimetableScreenState extends State<DeptAdminTimetableScreen> {
  final _api = ApiService();

  List<dynamic> _departments = [];
  List<dynamic> _classes = [];
  List<dynamic> _divisions = [];
  List<dynamic> _timetable = [];

  int? _selectedDeptId;
  String? _selectedClassId;
  String? _selectedClassName;
  int? _selectedDivisionId;

  bool _loadingClasses = false;
  bool _loadingDivisions = false;
  bool _loadingTimetable = false;
  bool _showForm = false;
  bool _saving = false;

  // Form controllers
  final _subjectCtrl = TextEditingController();
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  static const _amber = Color(0xFFF57C00);
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  static const _dayColors = {
    'Monday': Color(0xFF1976D2),
    'Tuesday': Color(0xFF388E3C),
    'Wednesday': Color(0xFF7B1FA2),
    'Thursday': Color(0xFFE64A19),
    'Friday': Color(0xFFF57C00),
    'Saturday': Color(0xFF0097A7),
  };

  @override
  void initState() {
    super.initState();
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    try {
      _departments = await _api.deptAdminGetDepartments();
      if (_departments.isNotEmpty) {
        _selectedDeptId = _departments.first['id'] as int;
        await _loadClasses();
      }
    } catch (_) {}
    setState(() {});
  }

  Future<void> _loadClasses() async {
    if (_selectedDeptId == null) return;
    setState(() => _loadingClasses = true);
    try {
      _classes = await _api.deptAdminGetClasses(_selectedDeptId!);
      _selectedClassId = null;
      _selectedDivisionId = null;
      _divisions = [];
      _timetable = [];
    } catch (_) {}
    setState(() => _loadingClasses = false);
  }

  Future<void> _loadDivisions() async {
    if (_selectedClassId == null) return;
    setState(() => _loadingDivisions = true);
    try {
      _divisions = await _api.deptAdminGetDivisions(_selectedClassId!);
      _selectedDivisionId = null;
      _timetable = [];
    } catch (_) {}
    setState(() => _loadingDivisions = false);
  }

  Future<void> _loadTimetable() async {
    if (_selectedClassId == null) return;
    setState(() => _loadingTimetable = true);
    try {
      _timetable = await _api.deptAdminGetTimetable(
        _selectedClassId!,
        _selectedDivisionId?.toString() ?? 'null',
      );
    } catch (_) {}
    setState(() => _loadingTimetable = false);
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty || _selectedDay == null ||
        _startTime == null || _endTime == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    setState(() => _saving = true);
    try {
      await _api.deptAdminCreateTimetableEntry(
        classId: _selectedClassId!,
        divisionId: _selectedDivisionId,
        subject: _subjectCtrl.text.trim(),
        dayOfWeek: _selectedDay!,
        startTime: fmt(_startTime!),
        endTime: fmt(_endTime!),
      );
      _subjectCtrl.clear();
      _selectedDay = null;
      _startTime = null;
      _endTime = null;
      setState(() => _showForm = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable entry added!'), backgroundColor: Colors.green),
        );
        await _loadTimetable();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _delete(int id) async {
    try {
      await _api.deptAdminDeleteTimetableEntry(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry removed'), backgroundColor: Colors.green),
        );
        await _loadTimetable();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';

  Map<String, List<dynamic>> _groupByDay() {
    final map = <String, List<dynamic>>{};
    for (final day in _days) map[day] = [];
    for (final entry in _timetable) {
      final d = entry['day_of_week'] as String? ?? '';
      map.putIfAbsent(d, () => []).add(entry);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _amber,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dept-admin'),
        ),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  if (_classes.isNotEmpty) ...[
                    Expanded(
                      child: _Dropdown<String>(
                        hint: 'Select Class',
                        value: _selectedClassId,
                        items: _classes.map((c) => DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text('${c['name']} ${c['section']}', overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) {
                          setState(() { _selectedClassId = v; _selectedClassName = _classes.firstWhere((c) => c['id'] == v)['name']; });
                          _loadDivisions().then((_) => _loadTimetable());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_divisions.isNotEmpty)
                    Expanded(
                      child: _Dropdown<int>(
                        hint: 'All Divisions',
                        value: _selectedDivisionId,
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('All Divs')),
                          ..._divisions.map((d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text('Div ${d['division_name']}'),
                          )),
                        ],
                        onChanged: (v) { setState(() => _selectedDivisionId = v); _loadTimetable(); },
                      ),
                    ),
                ]),
              ],
            ),
          ),

          // Add form
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
                        const Text('Add Timetable Entry',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _subjectCtrl,
                          decoration: InputDecoration(
                            hintText: 'Subject name',
                            prefixIcon: const Icon(Icons.book_rounded, size: 18),
                            filled: true, fillColor: const Color(0xFFF0F4F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedDay,
                          hint: const Text('Day of Week'),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                            filled: true, fillColor: const Color(0xFFF0F4F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => _selectedDay = v),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _TimePickerTile(
                            label: _startTime != null ? _fmtTime(_startTime!) : 'Start Time',
                            icon: Icons.access_time_rounded,
                            onTap: () => _pickTime(true),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _TimePickerTile(
                            label: _endTime != null ? _fmtTime(_endTime!) : 'End Time',
                            icon: Icons.access_time_filled_rounded,
                            onTap: () => _pickTime(false),
                          )),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: _amber,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Timetable view
          Expanded(
            child: _loadingTimetable
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId == null
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Select a class to view timetable', style: TextStyle(color: Colors.grey.shade500)),
                        ]),
                      )
                    : _timetable.isEmpty
                        ? Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No timetable entries yet', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: () => setState(() => _showForm = true),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Entry'),
                                style: FilledButton.styleFrom(backgroundColor: _amber),
                              ),
                            ]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: grouped.entries.where((e) => e.value.isNotEmpty).length,
                            itemBuilder: (ctx, i) {
                              final entry = grouped.entries.where((e) => e.value.isNotEmpty).toList()[i];
                              final color = _dayColors[entry.key] ?? _amber;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                        child: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                      ),
                                    ]),
                                  ),
                                  ...entry.value.map((slot) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: color.withOpacity(0.3)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                        child: Icon(Icons.book_rounded, color: color, size: 18),
                                      ),
                                      title: Text(slot['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      subtitle: Text(
                                        '${slot['start_time']?.toString().substring(0, 5) ?? ''} – ${slot['end_time']?.toString().substring(0, 5) ?? ''}  •  ${slot['teacher_name'] ?? 'No teacher'}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                        onPressed: () => _delete(slot['id'] as int),
                                      ),
                                    ),
                                  )).toList(),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TimePickerTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFFF57C00)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }
}
