import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';
import 'user_filter_widget.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  int _total = 0;
  bool _loading = true;

  // Filters
  String _roleFilter = '';
  String _deptFilter = '';
  String _statusFilter = '';
  String _sortFilter = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await _api.fetchAdminUsers(
        role: _roleFilter,
        dept: _deptFilter,
        status: _statusFilter,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _users = data['users'] as List<dynamic>;
          _total = data['total'] as int;

          // Client-side sorting fallback
          if (_sortFilter == 'name_asc') {
            _users.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          } else if (_sortFilter == 'name_desc') {
            _users.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
          } else if (_sortFilter == 'newest') {
            _users.sort((a, b) => (b['id'] ?? '').toString().compareTo((a['id'] ?? '').toString()));
          } else if (_sortFilter == 'oldest') {
            _users.sort((a, b) => (a['id'] ?? '').toString().compareTo((b['id'] ?? '').toString()));
          }

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to permanently delete "$name"?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteAdminUser(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted'), backgroundColor: Colors.green),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await _api.toggleAdminUserStatus(id, !currentStatus);
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddUserRoleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select User Type'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleDialogOption('Student', Icons.school_rounded, const Color(0xFF3B82F6), () {
              Navigator.pop(ctx);
              context.push('/add-student/GLOBAL');
            }),
            _roleDialogOption('Parent', Icons.family_restroom_rounded, const Color(0xFFF59E0B), () {
              Navigator.pop(ctx);
              context.push('/admin/users/new');
            }),
            _roleDialogOption('Dept Admin', Icons.manage_accounts_rounded, const Color(0xFF8B5CF6), () {
              Navigator.pop(ctx);
              context.push('/admin/create-dept-admin');
            }),
          ],
        ),
      ),
    );
  }

  Widget _roleDialogOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF3B82F6);
      case 'Teacher': return const Color(0xFF10B981);
      case 'Parent':  return const Color(0xFFF59E0B);
      case 'Admin':   return const Color(0xFF8B5CF6);
      case 'DEPARTMENT_ADMIN': return const Color(0xFF7C3AED);
      default:        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Student': return Icons.school_rounded;
      case 'Teacher': return Icons.person_rounded;
      case 'Parent':  return Icons.family_restroom_rounded;
      case 'Admin':   return Icons.admin_panel_settings_rounded;
      case 'DEPARTMENT_ADMIN': return Icons.manage_accounts_rounded;
      default:        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'User Management',
      child: Column(
        children: [
          // ─── CONTROL BAR ───
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or ID...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value.trim());
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(Icons.person_add_rounded, 'Add User', _showAddUserRoleDialog, AppTheme.adminAccent),
                const SizedBox(width: 12),
                _buildActionButton(Icons.upload_file_rounded, 'Bulk Import', () => context.push('/admin/users/bulk'), Colors.blueGrey),
              ],
            ),
          ),

          // ─── FILTERS ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white,
            child: UserFilterWidget(
              selectedRole: _roleFilter,
              selectedDept: _deptFilter,
              selectedStatus: _statusFilter,
              selectedSort: _sortFilter,
              onFiltersChanged: (role, dept, status, sort) {
                setState(() {
                  _roleFilter = role;
                  _deptFilter = dept;
                  _statusFilter = status;
                  _sortFilter = sort;
                });
                _loadUsers();
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ─── DATA CONTENT ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return _buildUserTable();
                      } else {
                        return _buildUserList();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowHeight: 70,
          columns: const [
            DataColumn(label: Text('USER', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _users.map((user) {
            final role = (user['role'] as String?) ?? 'Unknown';
            final isActive = user['is_active'] == 1 || user['is_active'] == true || user['is_active'] == null;
            final color = _roleColor(role);

            return DataRow(cells: [
              DataCell(
                InkWell(
                  onTap: () => context.push('/admin/users/profile/${user['id']}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(_roleIcon(role), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminAccent)),
                          Text(user['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text(user['dept'] ?? 'N/A')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                      tooltip: 'View Profile',
                      onPressed: () => context.push('/admin/users/profile/${user['id']}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => context.push('/admin/users/edit/${user['id']}').then((_) => _loadUsers()),
                    ),
                    IconButton(
                      icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline, size: 20, color: isActive ? Colors.orange : Colors.green),
                      onPressed: () => _toggleStatus(user['id'], isActive),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteUser(user['id'], user['name'] ?? 'User'),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final role = (user['role'] as String?) ?? 'Unknown';
        final color = _roleColor(role);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(_roleIcon(role), color: color),
            ),
            title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user['role']} • ${user['dept'] ?? 'N/A'}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/admin/users/profile/${user['id']}'),
          ),
        );
      },
    );
  }
}
