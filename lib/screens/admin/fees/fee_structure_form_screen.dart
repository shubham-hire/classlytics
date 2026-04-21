import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/fee_structure.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class FeeStructureFormScreen extends StatefulWidget {
  final int? structureId; // null = create, non-null = edit

  const FeeStructureFormScreen({super.key, this.structureId});
  bool get isEditMode => structureId != null;

  @override
  State<FeeStructureFormScreen> createState() => _FeeStructureFormScreenState();
}

class _FeeStructureFormScreenState extends State<FeeStructureFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialLoading = true;

  // Controllers
  final _titleController = TextEditingController();
  final _tuitionController = TextEditingController(text: '0');
  final _examController = TextEditingController(text: '0');
  final _transportController = TextEditingController(text: '0');
  final _libraryController = TextEditingController(text: '0');
  final _sportsController = TextEditingController(text: '0');
  final _miscController = TextEditingController(text: '0');

  String? _selectedClassId;
  String _selectedYear = '2025-26';
  String? _selectedDueDate;
  List<dynamic> _classes = [];

  final List<String> _academicYears = ['2023-24', '2024-25', '2025-26', '2026-27'];

  double get _totalFee =>
      _parse(_tuitionController.text) +
      _parse(_examController.text) +
      _parse(_transportController.text) +
      _parse(_libraryController.text) +
      _parse(_sportsController.text) +
      _parse(_miscController.text);

  double _parse(String v) => double.tryParse(v) ?? 0;

  @override
  void initState() {
    super.initState();
    _initData();
    // Rebuild total on every keystroke
    for (final c in [_tuitionController, _examController, _transportController, _libraryController, _sportsController, _miscController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_titleController, _tuitionController, _examController, _transportController, _libraryController, _sportsController, _miscController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      _classes = await _api.fetchAdminClasses();
      if (widget.isEditMode) {
        final data = await _api.fetchFeeStructureById(widget.structureId!);
        final fs = FeeStructure.fromJson(data);
        _titleController.text = fs.title;
        _selectedClassId = fs.classId;
        _selectedYear = fs.academicYear;
        _selectedDueDate = fs.dueDate;
        _tuitionController.text = fs.tuitionFee.toStringAsFixed(0);
        _examController.text = fs.examFee.toStringAsFixed(0);
        _transportController.text = fs.transportFee.toStringAsFixed(0);
        _libraryController.text = fs.libraryFee.toStringAsFixed(0);
        _sportsController.text = fs.sportsFee.toStringAsFixed(0);
        _miscController.text = fs.miscellaneousFee.toStringAsFixed(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _loading = true);
    final data = {
      'class_id': _selectedClassId,
      'academic_year': _selectedYear,
      'title': _titleController.text.trim(),
      'tuition_fee': _parse(_tuitionController.text),
      'exam_fee': _parse(_examController.text),
      'transport_fee': _parse(_transportController.text),
      'library_fee': _parse(_libraryController.text),
      'sports_fee': _parse(_sportsController.text),
      'miscellaneous_fee': _parse(_miscController.text),
      'due_date': _selectedDueDate,
    };

    try {
      if (widget.isEditMode) {
        await _api.updateFeeStructure(widget.structureId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully'), backgroundColor: Colors.green));
          context.pop(true);
        }
      } else {
        await _api.createFeeStructure(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee structure created!'), backgroundColor: Colors.green));
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: Error creating fee structure: Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'Edit Fee Structure' : 'New Fee Structure',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Total Banner ───
                    _buildTotalBanner(),
                    const SizedBox(height: 20),

                    // ─── Basic Info ───
                    _sectionLabel('Basic Information'),
                    const SizedBox(height: 12),
                    _card([
                      _textField(_titleController, 'Structure Title', Icons.label_rounded, required: true, hint: 'e.g. Annual Fee 2025-26'),
                      const SizedBox(height: 14),
                      // Class Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: _dec('Assign to Class', Icons.class_rounded),
                        isExpanded: true,
                        items: _classes.map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text('${c['name']} - ${c['section']}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedClassId = v),
                        validator: (v) => v == null ? 'Please select a class' : null,
                      ),
                      const SizedBox(height: 14),
                      // Academic Year
                      DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: _dec('Academic Year', Icons.calendar_today_rounded),
                        items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                      const SizedBox(height: 14),
                      // Due Date
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _dec('Due Date (optional)', Icons.event_rounded).copyWith(
                              hintText: _selectedDueDate ?? 'Tap to select',
                              suffixIcon: const Icon(Icons.calendar_month_rounded),
                            ),
                            controller: TextEditingController(text: _selectedDueDate ?? ''),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    // ─── Fee Components ───
                    _sectionLabel('Fee Components'),
                    const SizedBox(height: 12),
                    _card([
                      _feeField(_tuitionController, 'Tuition Fee', Icons.school_rounded, const Color(0xFF3B82F6)),
                      _feeField(_examController, 'Exam Fee', Icons.assignment_rounded, const Color(0xFFF59E0B)),
                      _feeField(_transportController, 'Transport Fee', Icons.directions_bus_rounded, const Color(0xFF10B981)),
                      _feeField(_libraryController, 'Library Fee', Icons.local_library_rounded, const Color(0xFF8B5CF6)),
                      _feeField(_sportsController, 'Sports Fee', Icons.sports_soccer_rounded, const Color(0xFFEF4444)),
                      _feeField(_miscController, 'Miscellaneous Fee', Icons.more_horiz_rounded, const Color(0xFF6B7280)),
                    ]),

                    const SizedBox(height: 28),
                    // ─── Submit ───
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                widget.isEditMode ? 'Save Changes' : 'Create Fee Structure',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Fee Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '₹${_totalFee.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feeField(TextEditingController ctrl, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color, size: 20),
          prefixText: '₹ ',
          filled: true,
          fillColor: color.withOpacity(0.04),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
        validator: (v) {
          if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {bool required = false, String? hint}) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(label, icon).copyWith(hintText: hint),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
    );
  }

  Widget _sectionLabel(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
  );
}
