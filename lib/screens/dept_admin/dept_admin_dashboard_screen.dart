import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_store.dart';

class DeptAdminDashboardScreen extends StatefulWidget {
  const DeptAdminDashboardScreen({super.key});

  @override
  State<DeptAdminDashboardScreen> createState() => _DeptAdminDashboardScreenState();
}

class _DeptAdminDashboardScreenState extends State<DeptAdminDashboardScreen> {
  final _api = ApiService();
  List<dynamic> _departments = [];
  bool _loading = true;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF0F9D8C), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _departments = await _api.deptAdminGetDepartments();
    } catch (_) {}
    setState(() => _loading = false);
  }

  final _menuItems = [
    {'icon': Icons.domain_rounded, 'label': 'My Department', 'route': '/dept-admin/department', 'color': Color(0xFF0F9D8C)},
    {'icon': Icons.class_rounded, 'label': 'Classes', 'route': '/dept-admin/classes', 'color': Color(0xFF1976D2)},
    {'icon': Icons.account_tree_rounded, 'label': 'Divisions', 'route': '/dept-admin/divisions', 'color': Color(0xFF7B1FA2)},
    {'icon': Icons.people_alt_rounded, 'label': 'Students', 'route': '/dept-admin/students', 'color': Color(0xFFE64A19)},
    {'icon': Icons.calendar_month_rounded, 'label': 'Timetable', 'route': '/dept-admin/timetable', 'color': Color(0xFFF57C00)},
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF0F9D8C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: _gradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Department Admin', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500)),
                                  Text(user?['name'] ?? 'Admin',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              onPressed: () {
                                ApiService.clearAuthToken();
                                AuthStore.instance.clear();
                                context.go('/login');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Action Cards
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.domain_rounded,
                                label: 'Department',
                                color: Colors.white.withOpacity(0.2),
                                onTap: () => context.go('/dept-admin/department'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.person_rounded,
                                label: 'My Profile',
                                color: Colors.white.withOpacity(0.2),
                                onTap: () => context.go('/dept-admin/profile'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: null, // Removed title to prevent overlap
            ),
          ),

          // Main Menu Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = _menuItems[i];
                  return _MenuCard(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    color: item['color'] as Color,
                    onTap: () => context.go(item['route'] as String),
                  );
                },
                childCount: _menuItems.length,
              ),
            ),
          ),

          // Footer Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'You are managing academic resources for your assigned department.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
