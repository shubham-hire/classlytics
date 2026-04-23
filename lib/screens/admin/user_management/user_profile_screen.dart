import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchAdminUserById(widget.userId);
      setState(() {
        _userData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateAIFeedback() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing student data...', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Generating personalized feedback...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await _api.generateStudentFeedback(widget.userId);
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              const Text('AI Academic Feedback'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feedback for ${result['studentName']}\'s parents:', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: MarkdownBody(
                    data: result['feedback'],
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Future: Add copy to clipboard or send functionality
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback ready to be shared!'))
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate AI feedback: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'User Profile',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadUserProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_userData == null) return const Center(child: Text('No data found'));

    final role = (_userData!['role'] as String?) ?? 'Student';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(role),
          const SizedBox(height: 24),
          _buildInfoSection('Basic Information', [
            _infoTile(Icons.email_rounded, 'Email', _userData!['email'] ?? 'N/A'),
            _infoTile(Icons.phone_rounded, 'Phone', _userData!['phone'] ?? 'N/A'),
            _infoTile(Icons.location_on_rounded, 'Address', _userData!['address'] ?? 'N/A'),
          ]),
          const SizedBox(height: 24),
          if (role == 'Student') _buildStudentDetails(),
          if (role == 'Teacher') _buildTeacherDetails(),
          if (role == 'Parent') _buildParentDetails(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String role) {
    Color roleColor = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_getRoleIcon(role), color: roleColor, size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData!['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${widget.userId}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_userData != null)
            IconButton(
              onPressed: () => context.push('/admin/users/edit/${widget.userId}').then((_) => _loadUserProfile()),
              icon: const Icon(Icons.edit_rounded, color: AppTheme.adminAccent),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
    );
  }

  Widget _buildStudentDetails() {
    return _buildInfoSection('Academic Details', [
      _infoTile(Icons.school_rounded, 'Class', _userData!['class_id'] ?? 'Not Assigned'),
      _infoTile(Icons.numbers_rounded, 'Roll Number', _userData!['roll_no'] ?? 'N/A'),
      _infoTile(Icons.business_rounded, 'Department', _userData!['dept'] ?? 'N/A'),
      _infoTile(Icons.calendar_today_rounded, 'Batch Year', _userData!['batch_year'] ?? 'N/A'),
      const Divider(height: 32),
      _statsRow([
        _statCard('Attendance', '${_userData!['attendance_percentage'] ?? 0}%', Colors.blue),
        _statCard('Avg Marks', '${_userData!['average_marks'] ?? 0}', Colors.orange),
      ]),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _generateAIFeedback,
          icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.purple),
          label: const Text('✨ Generate AI Feedback', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.purple, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.purple.withOpacity(0.02),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTeacherDetails() {
    return _buildInfoSection('Professional Details', [
      _infoTile(Icons.book_rounded, 'Primary Subject', _userData!['subject'] ?? 'N/A'),
      _infoTile(Icons.business_rounded, 'Department', _userData!['dept'] ?? 'N/A'),
      _infoTile(Icons.class_rounded, 'Assigned Classes', _userData!['assigned_classes'] ?? 'None'),
      _infoTile(Icons.work_rounded, 'Experience', '${_userData!['experience'] ?? 0} Years'),
    ]);
  }

  Widget _buildParentDetails() {
    return _buildInfoSection('Child Details', [
      _infoTile(Icons.child_care_rounded, 'Child Name', _userData!['child_name'] ?? 'N/A'),
      _infoTile(Icons.badge_rounded, 'Child ID', _userData!['child_id'] ?? 'N/A'),
      _infoTile(Icons.school_rounded, 'Child Class', _userData!['child_class'] ?? 'N/A'),
    ]);
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _statsRow(List<Widget> children) {
    return Row(
      children: children.expand((w) => [Expanded(child: w), const SizedBox(width: 12)]).toList()..removeLast(),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF3B82F6);
      case 'Teacher': return const Color(0xFF10B981);
      case 'Parent':  return const Color(0xFFF59E0B);
      case 'Admin':   return const Color(0xFF8B5CF6);
      default:        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Student': return Icons.school_rounded;
      case 'Teacher': return Icons.person_rounded;
      case 'Parent':  return Icons.family_restroom_rounded;
      case 'Admin':   return Icons.admin_panel_settings_rounded;
      default:        return Icons.person_outline;
    }
  }
}
