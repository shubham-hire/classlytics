import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../services/api_service.dart';
import '../../../models/department.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';

class UserFormScreen extends StatefulWidget {
  final String? userId; // null = create mode, non-null = edit mode

  const UserFormScreen({super.key, this.userId});

  bool get isEditMode => userId != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialLoading = true;
  String? _createdTempPassword;

  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _deptController = TextEditingController();
  String _selectedRole = 'Student';
  String _selectedCountry = 'India';
  String? _selectedState;
  String? _selectedStateCode;
  String? _selectedCity;

  // Student-specific Parent info
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentRelationController = TextEditingController();
  
  List<dynamic> _states = [];
  List<dynamic> _cities = [];
  bool _isLoadingGeo = false;
  String? _geoError;

  // Student-specific
  final _dobController = TextEditingController();
  String _selectedYear = 'First Year';

  // Parent-specific
  String _selectedRelation = 'Guardian';
  String? _selectedChildId;

  // Dropdown data
  List<dynamic> _classes = [];
  List<dynamic> _studentsList = [];

  final List<String> _roles = ['Student', 'Parent', 'Admin'];
  final List<String> _years = [
    'First Year', 'Second Year', 'Third Year', 'Fourth Year',
    '10th Grade', '11th Grade', '12th Grade'
  ];
  final List<String> _relations = ['Father', 'Mother', 'Guardian', 'Other'];
  List<Department> _departmentList = [];
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _deptController.dispose();
    _dobController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _parentRelationController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      // Load dropdown data
      final classesF = _api.fetchAdminClasses();
      final studentsF = _api.fetchAdminStudentsList();
      final deptsF = _api.getDepartments();
      final results = await Future.wait<dynamic>([classesF, studentsF, deptsF]);
      _classes = results[0] as List<dynamic>;
      _studentsList = results[1] as List<dynamic>;
      _departmentList = results[2] as List<Department>;
      
      await _loadStates();

      // If edit mode, load user data
      if (widget.isEditMode) {
        final user = await _api.fetchAdminUserById(widget.userId!);
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
        _selectedRole = user['role'] ?? 'Student';
        _selectedDeptId = user['department_id'];
        _selectedCountry = user['country'] ?? 'India';
        _selectedState = user['state'];
        _selectedCity = user['city'];

        if (_selectedState != null) {
          // Find state code for cities loading
          try {
            final stateObj = _states.firstWhere((s) => s['name'] == _selectedState, orElse: () => null);
            if (stateObj != null) {
              _selectedStateCode = stateObj['isoCode'];
              await _loadCities(_selectedStateCode!);
              // Re-set city after loading list
              _selectedCity = user['city'];
            }
          } catch (_) {}
        }

        if (_selectedRole == 'Student') {
          _dobController.text = user['dob'] != null ? user['dob'].toString().split('T')[0] : '';
          
          final yr = user['current_year'];
          if (yr != null && yr.toString().isNotEmpty) {
            // Safety: If value not in list, add it to prevent crash
            if (!_years.contains(yr)) {
              _years.add(yr);
            }
            _selectedYear = yr;
          } else {
            _selectedYear = 'First Year';
          }
        } else if (_selectedRole == 'Parent') {
          _selectedRelation = user['relation'] ?? 'Guardian';
          _selectedChildId = user['child_id'];
        }
        
        // Load parent info if it exists in user object
        if (_selectedRole == 'Student') {
          _parentNameController.text = user['parent_name'] ?? '';
          _parentPhoneController.text = user['parent_phone'] ?? '';
          _parentEmailController.text = user['parent_email'] ?? '';
          _parentRelationController.text = user['parent_relation'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'department_id': _selectedDeptId,
      'country': _selectedCountry,
      'state': _selectedState ?? '',
      'city': _selectedCity ?? '',
    };

    // Student-specific
    if (_selectedRole == 'Student') {
      data['dob'] = _dobController.text.trim();
      data['currentYear'] = _selectedYear;
      
      // Detailed fields
      data['parentName'] = _parentNameController.text.trim();
      data['parentPhone'] = _parentPhoneController.text.trim();
      data['parentEmail'] = _parentEmailController.text.trim();
      data['parentRelation'] = _parentRelationController.text.trim();
    }

    // Parent-specific
    if (_selectedRole == 'Parent') {
      data['relation'] = _selectedRelation;
      data['childId'] = _selectedChildId ?? '';
    }

    try {
      if (widget.isEditMode) {
        await _api.updateAdminUser(widget.userId!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
          );
          context.pop(true);
        }
      } else {
        final result = await _api.createAdminUser(data);
        if (mounted) {
          setState(() {
            _createdTempPassword = result['tempPassword'];
          });
          _showSuccessDialog(result);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: Error creating user: Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingGeo = true;
      _geoError = null;
    });
    try {
      final states = await _api.fetchStates();
      setState(() => _states = states);
    } catch (e) {
      setState(() => _geoError = 'Failed to load states: $e');
    } finally {
      setState(() => _isLoadingGeo = false);
    }
  }

  Future<void> _loadCities(String stateCode) async {
    setState(() {
      _isLoadingGeo = true;
      _cities = [];
    });
    try {
      final cities = await _api.fetchCities(stateCode);
      setState(() => _cities = cities);
    } catch (e) {
      debugPrint('City fetch error: $e');
    } finally {
      setState(() => _isLoadingGeo = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('User Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result['studentId'] != null) ...[
              _infoRow('Student ID', result['studentId']),
              const SizedBox(height: 8),
            ],
            _infoRow('User ID', result['userId'] ?? ''),
            const SizedBox(height: 8),
            _infoRow('Temp Password', result['tempPassword'] ?? ''),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Save these credentials! The password is shown only once.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Reset form for another entry
              _formKey.currentState?.reset();
              _nameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _addressController.clear();
              _dobController.clear();
              setState(() => _createdTempPassword = null);
            },
            child: const Text('Add Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/admin/users');
            },
            child: const Text('Go to User List'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = picked.toIso8601String().split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: widget.isEditMode ? 'Edit User' : 'Add New User',
      child: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button row
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (widget.isEditMode) {
                              context.pop();
                            } else {
                              context.go('/admin/users');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back to Users'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── ROLE SELECTOR ───
                    if (!widget.isEditMode) ...[
                      _sectionTitle('Role'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _roles.map((role) {
                          final isSelected = _selectedRole == role;
                          final color = _roleColor(role);
                          return ChoiceChip(
                            label: Text(role, style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.w700,
                            )),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedRole = role),
                            selectedColor: color,
                            backgroundColor: color.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _roleColor(_selectedRole).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(_roleIcon(_selectedRole), color: _roleColor(_selectedRole)),
                            const SizedBox(width: 10),
                            Text('Editing $_selectedRole', style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _roleColor(_selectedRole),
                              fontSize: 15,
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ─── BASIC INFO ───
                    _sectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    _card([
                      _textField(_nameController, 'Full Name', Icons.person_rounded, required: true),
                      _textField(_emailController, 'Email Address', Icons.email_rounded,
                          required: true, keyboardType: TextInputType.emailAddress,
                          enabled: !widget.isEditMode),
                      _textField(_phoneController, 'Phone Number', Icons.phone_rounded,
                          keyboardType: TextInputType.phone),
                      DropdownButtonFormField<int>(
                        value: _selectedDeptId,
                        decoration: _inputDecoration('Department', Icons.business_rounded),
                        items: _departmentList.map((d) => DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(d.name),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedDeptId = v),
                        validator: (v) => (v == null) ? 'Department is required' : null,
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _sectionTitle('Location Details'),
                    const SizedBox(height: 12),
                    _card([
                      // Country
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: _inputDecoration('Country', Icons.language_rounded),
                        items: const [DropdownMenuItem(value: 'India', child: Text('India'))],
                        onChanged: null, // Locked for now
                      ),
                      const SizedBox(height: 14),
                      // State
                      DropdownSearch<String>(
                        items: (f, l) => _states.map((s) => s['name'].toString()).where((i) => i.toLowerCase().contains(f.toLowerCase())).toList(),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _inputDecoration('State', Icons.map_rounded).copyWith(
                            suffixIcon: _isLoadingGeo && _states.isEmpty ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                          ),
                        ),
                        popupProps: const PopupProps.menu(showSearchBox: true),
                        onSelected: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedState = val;
                            _selectedStateCode = _states.firstWhere((s) => s['name'] == val)['isoCode'].toString();
                          });
                          _loadCities(_selectedStateCode!);
                        },
                        selectedItem: _selectedState,
                      ),
                      const SizedBox(height: 14),
                      // City
                      DropdownSearch<String>(
                        items: (f, l) => _cities.map((c) => c['name'].toString()).where((i) => i.toLowerCase().contains(f.toLowerCase())).toList(),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _inputDecoration('City / Village', Icons.location_city_rounded).copyWith(
                            suffixIcon: _isLoadingGeo && _cities.isEmpty && _selectedStateCode != null ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                          ),
                        ),
                        popupProps: const PopupProps.menu(showSearchBox: true),
                        onSelected: (val) => setState(() => _selectedCity = val),
                        selectedItem: _selectedCity,
                        enabled: _selectedStateCode != null,
                      ),
                      const SizedBox(height: 14),
                      _textField(_addressController, 'Address', Icons.location_on_rounded, maxLines: 2),
                    ]),

                    // ─── STUDENT-SPECIFIC ───
                    if (_selectedRole == 'Student') ...[
                      const SizedBox(height: 20),
                      _sectionTitle('Student Details'),
                      const SizedBox(height: 12),
                      _card([
                        // Year dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedYear,
                          decoration: _inputDecoration('Current Year', Icons.calendar_today_rounded),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                        // DOB picker
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: _inputDecoration('Date of Birth', Icons.cake_rounded).copyWith(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month_rounded),
                              onPressed: _pickDate,
                            ),
                          ),
                          onTap: _pickDate,
                        ),
                      ]),

                      const SizedBox(height: 20),
                      _sectionTitle('Parent / Guardian Details'),
                      const SizedBox(height: 12),
                      _card([
                        _textField(_parentNameController, 'Parent Name', Icons.person_rounded),
                        DropdownButtonFormField<String>(
                          value: _parentRelationController.text.isEmpty ? null : _parentRelationController.text,
                          decoration: _inputDecoration('Relation', Icons.family_restroom_rounded),
                          items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setState(() => _parentRelationController.text = v ?? ''),
                        ),
                        const SizedBox(height: 14),
                        _textField(_parentPhoneController, 'Parent Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
                        _textField(_parentEmailController, 'Parent Email Address', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                      ]),
                    ],

                    // ─── PARENT-SPECIFIC ───
                    if (_selectedRole == 'Parent') ...[
                      const SizedBox(height: 20),
                      _sectionTitle('Parent Details'),
                      const SizedBox(height: 12),
                      _card([
                        // Relation
                        DropdownButtonFormField<String>(
                          value: _selectedRelation,
                          decoration: _inputDecoration('Relation', Icons.family_restroom_rounded),
                          items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setState(() => _selectedRelation = v!),
                        ),
                        const SizedBox(height: 14),
                        // Link to student
                        DropdownButtonFormField<String>(
                          value: _selectedChildId,
                          decoration: _inputDecoration('Link to Student', Icons.link_rounded),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('No student linked', style: TextStyle(color: Colors.grey))),
                            ..._studentsList.map((s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text('${s['name']} (${s['id']})'),
                            )),
                          ],
                          onChanged: (v) => setState(() => _selectedChildId = v),
                        ),
                      ]),
                    ],



                    const SizedBox(height: 28),

                    // ─── SUBMIT BUTTON ───
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                widget.isEditMode ? 'Save Changes' : 'Create User',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Color _roleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF3B82F6);
      case 'Teacher': return const Color(0xFF10B981);
      case 'Parent':  return const Color(0xFFF59E0B);
      case 'Admin':   return const Color(0xFF8B5CF6);
      default:        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Student': return Icons.school_rounded;
      case 'Teacher': return Icons.person_rounded;
      case 'Parent':  return Icons.family_restroom_rounded;
      case 'Admin':   return Icons.admin_panel_settings_rounded;
      default:        return Icons.person_outline;
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _inputDecoration(label, icon),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
      ),
    );
  }
}
