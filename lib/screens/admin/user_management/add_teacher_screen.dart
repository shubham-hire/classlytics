import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/api_service.dart';
import '../../../../core/theme/app_theme.dart';

class AddTeacherScreen extends StatefulWidget {
  final String? teacherId;
  const AddTeacherScreen({super.key, this.teacherId});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _isEditing => widget.teacherId != null;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '0');
  final _prevSchoolCtrl = TextEditingController();
  final _bankAccCtrl = TextEditingController();
  final _bankIfscCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();

  // Dropdowns
  String _gender = 'Male';
  String _department = 'Computer Science';
  final List<String> _departments = ['Computer Science', 'Information Technology', 'Mechanical Engineering', 'Electronics & TC', 'Civil Engineering', 'Applied Sciences'];
  String _designation = 'Teacher';
  String _employmentType = 'Full-time';
  DateTime? _dob;
  DateTime? _joiningDate;

  // Image
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    setState(() => _isLoading = true);
    try {
      final t = await _api.fetchTeacherById(widget.teacherId!);
      setState(() {
        _nameCtrl.text = t['name'] ?? '';
        _emailCtrl.text = t['email'] ?? '';
        _phoneCtrl.text = t['phone'] ?? '';
        _addressCtrl.text = t['address'] ?? '';
        _cityCtrl.text = t['city'] ?? '';
        _stateCtrl.text = t['state'] ?? '';
        _countryCtrl.text = t['country'] ?? '';
        _qualificationCtrl.text = t['qualification'] ?? '';
        _specializationCtrl.text = t['specialization'] ?? '';
        _experienceCtrl.text = (t['experience_years'] ?? 0).toString();
        _prevSchoolCtrl.text = t['previous_school'] ?? '';
        _bankAccCtrl.text = t['bank_account_no'] ?? '';
        _bankIfscCtrl.text = t['bank_ifsc'] ?? '';
        _emergencyContactCtrl.text = t['emergency_contact'] ?? '';
        
        _gender = ['Male', 'Female', 'Other'].contains(t['gender']) ? t['gender'] : 'Male';
        _department = _departments.contains(t['department']) ? t['department'] : 'Computer Science';
        _designation = ['Teacher', 'HOD', 'Coordinator', 'Principal'].contains(t['designation']) ? t['designation'] : 'Teacher';
        _employmentType = ['Full-time', 'Part-time', 'Contract'].contains(t['employment_type']) ? t['employment_type'] : 'Full-time';
        
        if (t['dob'] != null) _dob = DateTime.tryParse(t['dob']);
        if (t['joining_date'] != null) _joiningDate = DateTime.tryParse(t['joining_date']);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDob ? DateTime(1990) : DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: const Color(0xFF6366F1),
          colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
          buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDob) _dob = picked; else _joiningDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final Map<String, dynamic> data = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender,
        'dob': _dob?.toIso8601String().split('T').first,
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        
        'department': _department,
        'designation': _designation,
        'employment_type': _employmentType,
        'joining_date': _joiningDate?.toIso8601String().split('T').first,
        
        'qualification': _qualificationCtrl.text.trim(),
        'specialization': _specializationCtrl.text.trim(),
        'experience_years': _experienceCtrl.text.trim(),
        'previous_school': _prevSchoolCtrl.text.trim(),
        
        'bank_account_no': _bankAccCtrl.text.trim(),
        'bank_ifsc': _bankIfscCtrl.text.trim(),
        'emergency_contact': _emergencyContactCtrl.text.trim(),
        
        'is_active': true,
      };

      if (!_isEditing) {
        data['email'] = _emailCtrl.text.trim();
        await _api.createTeacher(data, imagePath: _imageFile?.path);
      } else {
        await _api.updateTeacher(widget.teacherId!, data, imagePath: _imageFile?.path);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Teacher updated successfully!' : 'Teacher created successfully!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Teacher' : 'Add Teacher', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionCard(
                    'Personal Information',
                    Icons.person_rounded,
                    [
                      _buildImagePicker(),
                      const SizedBox(height: 16),
                      _buildField(_nameCtrl, 'Full Name', Icons.badge_rounded, required: true),
                      const SizedBox(height: 12),
                      if (!_isEditing) ...[
                        _buildField(_emailCtrl, 'Email Address', Icons.email_rounded, required: true, isEmail: true),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Password will be auto-generated and sent via email.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(child: _buildField(_phoneCtrl, 'Phone Number', Icons.phone_rounded)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: _inputDeco('Gender', Icons.wc_rounded),
                              items: ['Male', 'Female', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDateField('Date of Birth', _dob, () => _selectDate(context, true)),
                    ],
                  ),
                  _buildSectionCard(
                    'Professional Details',
                    Icons.work_rounded,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _department,
                              decoration: _inputDeco('Department', Icons.account_tree_rounded),
                              items: _departments.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _department = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _designation,
                              decoration: _inputDeco('Designation', Icons.label_rounded),
                              items: ['Teacher', 'HOD', 'Coordinator', 'Principal'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _designation = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _employmentType,
                              decoration: _inputDeco('Employment Type', Icons.work_outline_rounded),
                              items: ['Full-time', 'Part-time', 'Contract'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _employmentType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDateField('Joining Date', _joiningDate, () => _selectDate(context, false))),
                        ],
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    'Qualification & Experience',
                    Icons.school_rounded,
                    [
                      _buildField(_qualificationCtrl, 'Highest Qualification', Icons.workspace_premium_rounded),
                      const SizedBox(height: 12),
                      _buildField(_specializationCtrl, 'Specialization', Icons.star_border_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(_experienceCtrl, 'Experience (Years)', Icons.timeline_rounded, isNumber: true)),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildField(_prevSchoolCtrl, 'Previous School', Icons.business_rounded)),
                        ],
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    'Address & Bank Details',
                    Icons.location_on_rounded,
                    [
                      _buildField(_addressCtrl, 'Address Line', Icons.home_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(_cityCtrl, 'City', Icons.location_city_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_stateCtrl, 'State', Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildField(_bankAccCtrl, 'Bank Account No', Icons.account_balance_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(_bankIfscCtrl, 'Bank IFSC', Icons.code_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(_emergencyContactCtrl, 'Emergency Contact Phone', Icons.warning_amber_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _save,
                    child: Text(_isEditing ? 'Save Changes' : 'Create Teacher Profile', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
          ),
          child: _imageFile == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_rounded, color: Color(0xFF94A3B8), size: 28),
                    SizedBox(height: 4),
                    Text('Upload', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool required = false, bool isEmail = false, bool isPassword = false, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDeco(label, icon),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'Required';
        if (isEmail && v != null && !v.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDeco(label, Icons.calendar_today_rounded),
        child: Text(date != null ? date.toIso8601String().split('T').first : 'Select Date', 
            style: TextStyle(color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary)),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
