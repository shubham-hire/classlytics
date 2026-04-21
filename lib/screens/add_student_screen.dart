import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/api_service.dart';

class AddStudentScreen extends StatefulWidget {
  final String classId;
  const AddStudentScreen({super.key, required this.classId});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  
  final _parentNameController = TextEditingController();
  final _parentRelationController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  
  String? _selectedYear;
  String? _selectedDept;
  
  String? _selectedState;
  String? _selectedStateCode;
  String? _selectedCity;
  String _selectedCountry = 'India';

  List<dynamic> _states = [];
  List<dynamic> _cities = [];
  bool _isLoadingGeo = false;
  String? _geoError;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Mechanical Engineering',
    'Electronics & TC',
    'Civil Engineering',
    'Applied Sciences'
  ];

  final List<String> _academicYears = [
    'First Year',
    'Second Year',
    'Third Year',
    'Final Year'
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingGeo = true;
      _geoError = null;
    });
    try {
      debugPrint('DEBUG: Fetching states from API...');
      final states = await _apiService.fetchStates();
      debugPrint('DEBUG: Received ${states.length} states');
      setState(() => _states = states);
    } catch (e) {
      debugPrint('DEBUG: State fetch error: $e');
      setState(() => _geoError = 'Failed to load states: $e');
    } finally {
      setState(() => _isLoadingGeo = false);
    }
  }

  Future<void> _loadCities(String stateCode) async {
    setState(() {
      _isLoadingGeo = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      debugPrint('DEBUG: Fetching cities for $stateCode...');
      final cities = await _apiService.fetchCities(stateCode);
      debugPrint('DEBUG: Received ${cities.length} cities');
      setState(() => _cities = cities);
    } catch (e) {
      debugPrint('DEBUG: City fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load cities: $e')));
    } finally {
      setState(() => _isLoadingGeo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register New Student', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_geoError != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.shade50,
                  width: double.infinity,
                  child: Text(_geoError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Full Name', Icons.person, 'Enter student name'),
              _buildTextField(_emailController, 'Official Email', Icons.email, 'Enter email (used for login)', isEmail: true),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, 'Enter 10-digit number'),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: IgnorePointer(
                    child: _buildTextField(_dobController, 'Date of Birth', Icons.cake, 'Select Date'),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Text('Academic Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              _buildDropdown('Department', _departments, _selectedDept, (val) => setState(() => _selectedDept = val)),
              _buildDropdown('Current Year', _academicYears, _selectedYear, (val) => setState(() => _selectedYear = val)),
              
              const SizedBox(height: 32),
              const Text('Address & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              
              // Country (Fixed to India)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownButtonFormField<String>(
                  value: 'India',
                  decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder(), prefixIcon: Icon(Icons.language)),
                  items: const [DropdownMenuItem(value: 'India', child: Text('India'))],
                  onChanged: null, // Locked
                ),
              ),

              // States Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownSearch<String>(
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search state...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  items: (filter, loadProps) => _states
                      .map((s) => s['name'].toString())
                      .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                      .toList(),
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.map),
                      suffixIcon: _isLoadingGeo && _states.isEmpty ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                  ),
                  onSelected: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedState = val;
                      _selectedStateCode = _states.firstWhere((element) => element['name'] == val)['isoCode'].toString();
                    });
                    _loadCities(_selectedStateCode!);
                  },
                  selectedItem: _selectedState,
                  validator: (val) => val == null ? 'Required' : null,
                ),
              ),

              // Cities Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownSearch<String>(
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  items: (filter, loadProps) => _cities
                      .map((c) => c['name'].toString())
                      .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                      .toList(),
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'City / Village',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_city),
                      suffixIcon: _isLoadingGeo && _cities.isEmpty && _selectedStateCode != null ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                  ),
                  onSelected: (val) => setState(() => _selectedCity = val),
                  selectedItem: _selectedCity,
                  validator: (val) => val == null ? 'Required' : null,
                  enabled: _selectedStateCode != null,
                ),
              ),

              _buildTextField(_addressController, 'Detailed Address / House No.', Icons.home, 'Enter street details', maxLines: 2),
              
              const SizedBox(height: 16),
              const Text('Parent / Guardian Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              
              _buildTextField(_parentNameController, 'Parent Name', Icons.person, 'Enter parent/guardian name'),
              _buildDropdown('Relationship', ['Father', 'Mother', 'Guardian'], null, (val) => _parentRelationController.text = val ?? ''),
              _buildTextField(_parentPhoneController, 'Parent Phone Number', Icons.phone, 'Enter 10-digit number'),
              _buildTextField(_parentEmailController, 'Parent Email', Icons.email, 'Enter parent email (used for login)', isEmail: true),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Student & Send Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Student will receive an automated email with their generated password.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {bool isEmail = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
          filled: true,
          fillColor: Colors.blueGrey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (isEmail && !value.contains('@')) return 'Invalid email';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF1E3A8A)),
          filled: true,
          fillColor: Colors.blueGrey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Required' : null,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _apiService.addStudentWithParent(
        studentName: _nameController.text,
        studentEmail: _emailController.text,
        parentName: _parentNameController.text,
        relation: _parentRelationController.text.isEmpty ? 'Guardian' : _parentRelationController.text,
        parentPhone: _parentPhoneController.text,
        parentEmail: _parentEmailController.text,
        address: _addressController.text,
        country: _selectedCountry,
        state: _selectedState!,
        district: 'N/A',
        city: _selectedCity!,
        classId: widget.classId,
        dob: _dobController.text,
        currentYear: _selectedYear!,
        dept: _selectedDept!,
        rollNo: '', // Will be updated later or passed if needed
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student & Parent registered! Credentials sent to parent email.')));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
