import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          if (_userData != null)
            TextButton.icon(
              onPressed: () => context.push('/admin/users/edit/${widget.userId}').then((_) => _loadUserProfile()),
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
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
