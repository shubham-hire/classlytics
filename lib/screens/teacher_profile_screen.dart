import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:go_router/go_router.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            profile['name']?.substring(0, 1) ?? 'T',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile['name'] ?? 'Teacher Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile['designation'] ?? 'Class Teacher',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile['department'] ?? 'Department',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${profile['id']}',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement Edit Profile dialog/screen
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon')));
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Info Card
                _buildInfoCard('Personal Information', [
                  _buildInfoRow(Icons.email_outlined, 'Email', profile['email'] ?? 'N/A'),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', profile['phone'] ?? 'N/A'),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Joined', profile['joinDate'] ?? 'N/A'),
                  _buildInfoRow(Icons.school_outlined, 'Qualifications', profile['qualifications'] ?? 'N/A', isLast: true),
                ]),
                const SizedBox(height: 24),

                // Settings Card
                _buildInfoCard('Management & Settings', [
                  _buildSettingsRow(Icons.feedback_outlined, 'Student Feedback Inbox', () => context.push('/teacher-feedback')),
                  _buildSettingsRow(Icons.beach_access_outlined, 'Leave Management (HR)', () => context.push('/teacher-profile/leave')),
                  _buildSettingsRow(Icons.lock_outline, 'Change Password', () {}),
                  _buildSettingsRow(Icons.notifications_active_outlined, 'Notification Preferences', () {}, isLast: true),
                ]),
                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isLast ? 16 : 0), // lazy border radius approach
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.black54, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
