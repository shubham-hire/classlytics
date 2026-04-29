import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DeptAdminStatsScreen extends StatefulWidget {
  const DeptAdminStatsScreen({super.key});
  @override
  State<DeptAdminStatsScreen> createState() => _DeptAdminStatsScreenState();
}

class _DeptAdminStatsScreenState extends State<DeptAdminStatsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  late AnimationController _animController;

  static const _teal = Color(0xFF0F9D8C);
  static const _blue = Color(0xFF1976D2);
  static const _purple = Color(0xFF7B1FA2);
  static const _orange = Color(0xFFE64A19);
  static const _amber = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _stats = await _api.deptAdminGetStats();
      _animController.forward(from: 0);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ─── GRADIENT HEADER ───
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _teal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go('/dept-admin'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F9D8C), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.analytics_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stats?['department_name'] ?? 'My Department',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    'Statistics Dashboard',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white),
                              onPressed: _load,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── BODY ───
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.red.shade400, fontSize: 15)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // ─── TOP STAT CARDS ───
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Total Students',
                    value: '${_stats?['total_students'] ?? 0}',
                    color: _teal,
                    delay: 0,
                    animation: _animController,
                  ),
                  _StatCard(
                    icon: Icons.school_rounded,
                    label: 'Total Teachers',
                    value: '${_stats?['total_teachers'] ?? 0}',
                    color: _blue,
                    delay: 1,
                    animation: _animController,
                  ),
                  _StatCard(
                    icon: Icons.class_rounded,
                    label: 'Total Classes',
                    value: '${_stats?['total_classes'] ?? 0}',
                    color: _purple,
                    delay: 2,
                    animation: _animController,
                  ),
                  _StatCard(
                    icon: Icons.account_tree_rounded,
                    label: 'Total Divisions',
                    value: '${_stats?['total_divisions'] ?? 0}',
                    color: _orange,
                    delay: 3,
                    animation: _animController,
                  ),
                ]),
              ),
            ),

            // ─── YEAR-WISE BREAKDOWN ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bar_chart_rounded,
                                color: _amber, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Students by Year',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._buildYearBars(),
                    ],
                  ),
                ),
              ),
            ),

            // ─── QUICK ACTIONS ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add_circle_rounded,
                              label: 'New Class',
                              color: _blue,
                              onTap: () => context.go('/dept-admin/create-class'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.school_rounded,
                              label: 'Academic Hub',
                              color: _purple,
                              onTap: () => context.go('/dept-admin/academic-hub'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.people_alt_rounded,
                              label: 'Students',
                              color: _teal,
                              onTap: () => context.go('/dept-admin/academic-hub?tab=1'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.calendar_month_rounded,
                              label: 'Timetable',
                              color: _amber,
                              onTap: () => context.go('/dept-admin/timetable'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildYearBars() {
    final yearMap = _stats?['students_by_year'] as Map<String, dynamic>? ?? {};
    final totalStudents = _stats?['total_students'] ?? 1;

    if (yearMap.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No student data available',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
        ),
      ];
    }

    final yearColors = [_teal, _blue, _purple, _orange, _amber];

    return yearMap.entries.toList().asMap().entries.map((entry) {
      final idx = entry.key;
      final yearLabel = entry.value.key;
      final count = entry.value.value as int;
      final pct = totalStudents > 0 ? (count / totalStudents) : 0.0;
      final color = yearColors[idx % yearColors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  yearLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count students',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct.toDouble()),
                  duration: Duration(milliseconds: 800 + (idx * 200)),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ─── Animated Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;
  final AnimationController animation;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final t = Curves.easeOutBack
            .transform((animation.value - delay * 0.1).clamp(0.0, 1.0));
        return Transform.scale(
          scale: 0.5 + (0.5 * t),
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Button ─────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
