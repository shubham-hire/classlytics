import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import '../../../../core/theme/app_theme.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final ApiService _api = ApiService();

  String? _selectedClassId;
  List<dynamic> _classes = [];
  DateTime? _deadline;
  File? _mediaFile;
  bool _isSubmitting = false;

  String get _teacherId => AuthStore.instance.currentUser?['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _api.fetchClasses();
      setState(() => _classes = classes);
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _mediaFile = File(picked.path));
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
    if (time == null) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Attach File',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 24),
                  label: const Text('Take a Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                  icon: const Icon(Icons.photo_library_rounded, size: 24),
                  label: const Text('Choose from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class.')));
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a deadline.')));
      return;
    }

    // REQUIREMENT: Must have description or attachment or both
    if (_mediaFile == null && _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must either write instructions/questions OR attach an image.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baseUrl = ApiService.baseUrl;
      final uri = Uri.parse('$baseUrl/assignments');
      final request = http.MultipartRequest('POST', uri);
      request.fields['classId'] = _selectedClassId!;
      request.fields['teacherId'] = _teacherId;
      request.fields['title'] = _titleCtrl.text.trim();
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['deadline'] = _deadline!.toIso8601String();

      if (_mediaFile != null) {
        final ext = _mediaFile!.path.split('.').last.toLowerCase();
        final mime = (ext == 'pdf') ? 'application/pdf' : 'image/$ext';
        request.files.add(await http.MultipartFile.fromPath(
          'media', _mediaFile!.path,
          contentType: http.MediaType('application', mime.split('/').last),
        ));
      }

      final streamed = await request.send();
      if (streamed.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Assignment created and sent to students!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Server error: ${streamed.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── ATTACHMENT SECTION (TOP — most visible) ──────────
            _sectionLabel('📎  Attachment'),
            const SizedBox(height: 10),

            if (_mediaFile != null) ...[
              // Show selected image preview
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_mediaFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _mediaFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'File attached ✅  Tap ✕ to remove',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
            ] else ...[
              // Big prominent attach button
              ElevatedButton.icon(
                onPressed: _showAttachmentOptions,
                icon: const Icon(Icons.attach_file_rounded, size: 28),
                label: const Text(
                  'Tap to Attach Photo / Document',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can also write questions below instead.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),

            // ── ASSIGNMENT DETAILS ──────────────────────────────
            _sectionLabel('Assignment Details'),
            const SizedBox(height: 12),

            // Title
            _inputField(
              controller: _titleCtrl,
              label: 'Title',
              hint: 'e.g. Chapter 4 — Quadratic Equations',
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),

            // Description / Questions
            _inputField(
              controller: _descCtrl,
              label: 'Instructions / Questions',
              hint: 'Write the assignment questions or instructions here...',
              maxLines: 6,
            ),
            const SizedBox(height: 14),

            // Class picker
            _sectionLabel('Class'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  hint: const Text('Select class'),
                  isExpanded: true,
                  items: _classes.map<DropdownMenuItem<String>>((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text('${c['name']} — ${c['section']}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedClassId = v),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Deadline
            _sectionLabel('Deadline'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _deadline == null
                          ? 'Tap to set deadline'
                          : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}  ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _deadline == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                        fontWeight: _deadline != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publish Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
