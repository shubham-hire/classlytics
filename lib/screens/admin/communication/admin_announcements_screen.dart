import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_shell.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  bool _isLoadingClasses = false;
  bool _isSending = false;
  bool _isDrafting = false;
  
  List<dynamic> _classes = [];
  String? _selectedClassId;
  String _previewTitle = "Announcement Title";
  String _previewBody = "Your announcement message will appear here for parents to see...";

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _titleController.addListener(() {
      setState(() => _previewTitle = _titleController.text.isEmpty ? "Announcement Title" : _titleController.text);
    });
    _bodyController.addListener(() {
      setState(() => _previewBody = _bodyController.text.isEmpty ? "Your announcement message will appear here..." : _bodyController.text);
    });
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final classes = await _apiService.fetchAdminClasses();
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'].toString();
        }
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _draftWithAI() async {
    final promptController = TextEditingController();
    
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Smart AI Drafter', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What would you like to announce?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. Tomorrow is a half day due to staff meeting. School ends at 12 PM.',
                fillColor: Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, promptController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminAccent, padding: const EdgeInsets.symmetric(horizontal: 24)),
            child: const Text('Generate Draft'),
          ),
        ],
      ),
    );

    if (prompt != null && prompt.isNotEmpty) {
      setState(() => _isDrafting = true);
      try {
        final draft = await _apiService.draftAdminAnnouncement(prompt);
        setState(() {
          _bodyController.text = draft;
          if (_titleController.text.isEmpty) {
            _titleController.text = "School Announcement";
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isDrafting = false);
      }
    }
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await _apiService.sendAnnouncement(_selectedClassId!, _titleController.text, _bodyController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Announcement published successfully!'), backgroundColor: Colors.green));
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Communication Hub',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildComposeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.adminAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppTheme.adminAccent, size: 28),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Hub',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.adminPrimary, letterSpacing: -1),
                ),
                Text('Draft and broadcast professional notices to your community.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComposeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection
              const Text('Recipient Group', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              _isLoadingClasses 
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: _inputDecoration('Select Class or Group'),
                    items: _classes.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text('${c['name']} - ${c['section']}', style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                  ),
              const SizedBox(height: 24),

              // Title
              const Text('Subject / Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Sports Day Reschedule'),
                validator: (v) => v!.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 24),

              // Message Body
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Announcement Content', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  _buildAIButton(),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 10,
                decoration: _inputDecoration('Enter your message details...'),
                validator: (v) => v!.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publish Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: _isDrafting ? null : _draftWithAI,
        icon: _isDrafting 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
        label: const Text('Draft with AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.adminAccent, width: 2)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
