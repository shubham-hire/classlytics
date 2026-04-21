import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_ui_components.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadStats();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final data = await _api.fetchAdminStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _loading = false;
        });
        _animController.forward();
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

  @override
  Widget build(BuildContext context) {
    final byRole = (_stats['byRole'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // ─── HEADER ───
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E293B).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text(
                                      'Admin Control Center',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_stats['totalUsers'] ?? 0} total users · ${_stats['totalClasses'] ?? 0} classes',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── STAT CARDS ───
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3, // Increased aspect ratio for better mobile fit
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        delegate: SliverChildListDelegate([
                          SharedUIComponents.buildStatCard(
                            'Students',
                            '${byRole['Student'] ?? 0}',
                            Icons.school_rounded,
                            const Color(0xFF3B82F6),
                          ),
                          SharedUIComponents.buildStatCard(
                            'Teachers',
                            '${byRole['Teacher'] ?? 0}',
                            Icons.person_rounded,
                            const Color(0xFF10B981),
                          ),
                          SharedUIComponents.buildStatCard(
                            'Parents',
                            '${byRole['Parent'] ?? 0}',
                            Icons.family_restroom_rounded,
                            const Color(0xFFF59E0B),
                          ),
                          SharedUIComponents.buildStatCard(
                            'Active',
                            '${_stats['activeUsers'] ?? 0}',
                            Icons.verified_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                        ]),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ─── QUICK ACTIONS ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SharedUIComponents.buildSectionTitle('Quick Actions'),
                            const SizedBox(height: 14),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.people_alt_rounded,
                              title: 'Manage Users',
                              subtitle: 'View, search, filter all users',
                              color: const Color(0xFF3B82F6),
                              onTap: () => context.go('/admin/users'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.person_add_rounded,
                              title: 'Add New User',
                              subtitle: 'Create Student, Teacher, or Parent',
                              color: const Color(0xFF10B981),
                              onTap: () => context.go('/admin/users/new'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.badge_rounded,
                              title: 'Manage Teachers',
                              subtitle: 'View, add, edit ERP-standard teachers',
                              color: const Color(0xFF14B8A6),
                              onTap: () => context.go('/admin/teachers'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Fees & Finance',
                              subtitle: 'Manage fee structures for classes',
                              color: const Color(0xFF6366F1),
                              onTap: () => context.go('/admin/fees/structure'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.assignment_ind_rounded,
                              title: 'Assign Student Fees',
                              subtitle: 'Track paid, pending & assign fees',
                              color: const Color(0xFF0EA5E9),
                              onTap: () => context.go('/admin/fees/assignments'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.bar_chart_rounded,
                              title: 'Fee Reports',
                              subtitle: 'View overall fee collection insights',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => context.go('/admin/fees/reports'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.upload_file_rounded,
                              title: 'Bulk Upload',
                              subtitle: 'Import users from CSV data',
                              color: const Color(0xFFF59E0B),
                              onTap: () => context.go('/admin/users/bulk'),
                            ),
                            const SizedBox(height: 10),
                            SharedUIComponents.buildQuickActionTile(
                              icon: Icons.logout_rounded,
                              title: 'Back to Login',
                              subtitle: 'Return to login screen',
                              color: const Color(0xFFEF4444),
                              onTap: () => context.go('/login'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }
}

