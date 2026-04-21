import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final ApiService _api = ApiService();
  final _csvController = TextEditingController();
  String _selectedRole = 'Student';
  bool _uploading = false;
  Map<String, dynamic>? _result;

  final List<String> _roles = ['Student', 'Teacher', 'Parent', 'Admin'];

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseCsv(String csv) {
    final lines = csv.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // First line is header
    final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
    final users = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      final user = <String, dynamic>{'role': _selectedRole};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        final header = headers[j];
        // Map common header names to API field names
        switch (header) {
          case 'name':
          case 'full name':
          case 'fullname':
            user['name'] = values[j];
            break;
          case 'email':
          case 'email address':
            user['email'] = values[j];
            break;
          case 'phone':
          case 'mobile':
            user['phone'] = values[j];
            break;
          case 'dept':
          case 'department':
            user['dept'] = values[j];
            break;
          case 'roll':
          case 'rollno':
          case 'roll_no':
          case 'roll no':
            user['rollNo'] = values[j];
            break;
          case 'year':
          case 'current_year':
          case 'currentyear':
            user['currentYear'] = values[j];
            break;
          default:
            user[header] = values[j];
        }
      }
      if (user['name'] != null && user['email'] != null) {
        users.add(user);
      }
    }
    return users;
  }

  Future<void> _upload() async {
    final users = _parseCsv(_csvController.text);
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid data found. Check CSV format.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final result = await _api.bulkCreateAdminUsers(users);
      if (mounted) {
        setState(() {
          _result = result;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('Bulk Upload Users', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/users'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── INSTRUCTIONS ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.08),
                    const Color(0xFF8B5CF6).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('CSV Format Guide', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Paste your CSV data below. The first row must be headers.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const SelectableText(
                      'name,email,phone,dept,roll_no,current_year\nJohn Doe,john@example.com,9876543210,CS,1,1st Year\nJane Smith,jane@example.com,9876543211,IT,2,2nd Year',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Required columns: name, email. Other columns are optional.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── ROLE SELECTOR ───
            const Text('User Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _roles.map((role) {
                final isSelected = _selectedRole == role;
                return ChoiceChip(
                  label: Text(role, style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedRole = role),
                  selectedColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ─── CSV INPUT ───
            Container(
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
              child: TextField(
                controller: _csvController,
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste CSV data here...\n\nname,email,phone,dept\nAlice,alice@school.com,1234567890,CS',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── UPLOAD BUTTON ───
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(
                  _uploading ? 'Uploading...' : 'Upload & Create Users',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            // ─── RESULTS ───
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          _result!['message'] ?? 'Upload complete',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Created list
                    if ((_result!['created'] as List?)?.isNotEmpty == true) ...[
                      const Text('✅ Created:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                      const SizedBox(height: 6),
                      ...(_result!['created'] as List).map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${u['name']} (${u['email']})', style: const TextStyle(fontSize: 13))),
                            Text('Pass: ${u['tempPassword']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace')),
                          ],
                        ),
                      )),
                    ],

                    // Error list
                    if ((_result!['errors'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      const Text('❌ Errors:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                      const SizedBox(height: 6),
                      ...(_result!['errors'] as List).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Row ${e['row']}: ${e['error']}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                      )),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
