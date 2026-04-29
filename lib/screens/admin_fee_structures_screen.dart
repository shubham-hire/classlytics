import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminFeeStructuresScreen extends StatefulWidget {
  const AdminFeeStructuresScreen({super.key});

  @override
  State<AdminFeeStructuresScreen> createState() => _AdminFeeStructuresScreenState();
}

class _AdminFeeStructuresScreenState extends State<AdminFeeStructuresScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedDeptId;
  String? _selectedYear;
  String? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();

  List<dynamic> _departments = [];
  List<dynamic> _feeStructures = [];
  bool _isLoading = true;
  bool _isCreating = false;

  final List<String> _academicYears = ['First Year', 'Second Year', 'Third Year', 'Final Year'];
  final List<String> _categories = ['OPEN', 'SC_ST', 'EWS'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final depts = await _apiService.fetchDepartments();
      final fees = await _apiService.fetchCategoryFeeStructures();
      setState(() {
        _departments = depts;
        _feeStructures = fees;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createFeeStructure() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      await _apiService.createCategoryFeeStructure(
        departmentId: int.parse(_selectedDeptId!),
        year: _selectedYear!,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee Structure created successfully')));
        _formKey.currentState!.reset();
        setState(() {
          _selectedDeptId = null;
          _selectedYear = null;
          _selectedCategory = null;
          _amountController.clear();
        });
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Fee Structures', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Create New Fee Structure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDeptId,
                              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                              items: _departments.map((d) => DropdownMenuItem<String>(
                                value: d['id'].toString(),
                                child: Text(d['name'].toString()),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedDeptId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedYear,
                                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                                    items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                    onChanged: (val) => setState(() => _selectedYear = val),
                                    validator: (val) => val == null ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                    validator: (val) => val == null ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Amount (₹)', border: OutlineInputBorder()),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Required';
                                if (double.tryParse(val) == null) return 'Invalid amount';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: _isCreating ? null : _createFeeStructure,
                                child: _isCreating
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Create Structure', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Existing Structures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _feeStructures.isEmpty
                        ? const Center(child: Text('No fee structures found'))
                        : ListView.builder(
                            itemCount: _feeStructures.length,
                            itemBuilder: (context, index) {
                              final f = _feeStructures[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    child: Icon(Icons.account_balance_wallet, color: Colors.white),
                                  ),
                                  title: Text('${f['department_name'] ?? 'Unknown'} - ${f['year']}'),
                                  subtitle: Text('Category: ${f['category']} | Amount: ₹${f['amount']}'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
