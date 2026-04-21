import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

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
  String _statusFilter = '';
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
        status: _statusFilter,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _users = data['users'] as List<dynamic>;
          _total = data['total'] as int;
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

  Color _roleColor(String role) {
    switch (role) {
      case 'Student': return const Color(0xFF3B82F6);
      case 'Teacher': return const Color(0xFF10B981);
      case 'Parent':  return const Color(0xFFF59E0B);
      case 'Admin':   return const Color(0xFF8B5CF6);
      default:        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Student': return Icons.school_rounded;
      case 'Teacher': return Icons.person_rounded;
      case 'Parent':  return Icons.family_restroom_rounded;
      case 'Admin':   return Icons.admin_panel_settings_rounded;
      default:        return Icons.person_outline;
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
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add User',
            onPressed: () => context.go('/admin/users/new'),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Bulk Upload',
            onPressed: () => context.go('/admin/users/bulk'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── SEARCH + FILTERS ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or ID...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadUsers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value.trim());
                    _loadUsers();
                  },
                ),
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', '', isRole: true),
                      _filterChip('Student', 'Student', isRole: true),
                      _filterChip('Teacher', 'Teacher', isRole: true),
                      _filterChip('Parent', 'Parent', isRole: true),
                      _filterChip('Admin', 'Admin', isRole: true),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 24, color: Colors.grey.shade300),
                      const SizedBox(width: 12),
                      _filterChip('Active', 'active', isRole: false),
                      _filterChip('Inactive', 'inactive', isRole: false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── RESULT COUNT ───
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              children: [
                Text(
                  '$_total user${_total == 1 ? '' : 's'} found',
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _loadUsers,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // ─── USER LIST ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No users found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index] as Map<String, dynamic>;
                            return _userCard(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, {required bool isRole}) {
    final isSelected = isRole ? _roleFilter == value : _statusFilter == value;
    final color = isRole && value.isNotEmpty ? _roleColor(value) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        )),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (isRole) {
              _roleFilter = selected ? value : '';
            } else {
              _statusFilter = selected ? value : '';
            }
          });
          _loadUsers();
        },
        backgroundColor: Colors.white,
        selectedColor: isRole && value.isNotEmpty ? color : const Color(0xFF64748B),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final role = (user['role'] as String?) ?? 'Unknown';
    final isActive = user['is_active'] == 1 || user['is_active'] == true || user['is_active'] == null;
    final color = _roleColor(role);
    final studentId = user['student_id'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isActive ? Border.all(color: Colors.red.shade200, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await context.push('/admin/users/edit/${user['id']}');
            if (result == true) _loadUsers();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(_roleIcon(role), color: color, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Inactive', style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user['email'] ?? '',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          if (studentId != null) ...[
                            const SizedBox(width: 6),
                            Text(studentId, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                          if (user['dept'] != null && (user['dept'] as String).isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('· ${user['dept']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/admin/users/edit/${user['id']}').then((result) {
                        if (result == true) _loadUsers();
                      });
                    } else if (value == 'toggle') {
                      _toggleStatus(user['id'], isActive);
                    } else if (value == 'delete') {
                      _deleteUser(user['id'], user['name'] ?? 'User');
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(
                      children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')],
                    )),
                    PopupMenuItem(value: 'toggle', child: Row(
                      children: [
                        Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Activate'),
                      ],
                    )),
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
