import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_ui_components.dart';
import '../admin_shell.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _visualData = {};
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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
      final results = await Future.wait([_api.fetchAdminStats(), _api.fetchAdminVisualAnalytics()]);
      if (mounted) {
        setState(() { _stats = results[0]; _visualData = results[1]; _loading = false; });
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
    final now = DateTime.now();
    final dateStr = '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

    return AdminShell(
      title: 'Dashboard',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════ SECTION 1: HEADER ══════════
                    _SectionHeader(
                      title: 'Welcome back, Administrator 👋',
                      subtitle: dateStr,
                      trailing: _RefreshButton(onTap: () {
                        setState(() => _loading = true);
                        _animController.reset();
                        _loadStats();
                      }),
                    ),
                    const SizedBox(height: 16),

                    // ══════════ SECTION 2: KPI CARDS ══════════
                    _sectionLabel('Key Metrics'),
                    const SizedBox(height: 8),
                    _buildKpiRow(byRole),
                    const SizedBox(height: 16),

                    // ══════════ SECTION 3: ANALYTICS & MANAGEMENT ══════════
                    _sectionLabel('Analytics & Operations'),
                    const SizedBox(height: 8),
                    Expanded(child: _buildAnalyticsRow()),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Section label ──────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(
        color: AppTheme.adminAccent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        letterSpacing: 0.8, color: Color(0xFF64748B))),
    ]);
  }

  // ── KPI Row ────────────────────────────────────────────────
  Widget _buildKpiRow(Map<String, dynamic> byRole) {
    final cards = [
      _KpiData('Total Students',  '${byRole['Student'] ?? 0}',  Icons.school_rounded,         const Color(0xFF3B82F6), '+3 this week'),
      _KpiData('Active Teachers', '${byRole['Teacher'] ?? 0}',  Icons.person_rounded,         const Color(0xFF10B981), 'All assigned'),
      _KpiData('Registered Parents','${byRole['Parent'] ?? 0}', Icons.family_restroom_rounded, const Color(0xFFF59E0B), 'Linked to students'),
      _KpiData('Active Sessions', '${_stats['activeUsers'] ?? 0}', Icons.bolt_rounded,         const Color(0xFF8B5CF6), 'Right now'),
    ];
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 1100 ? 4 : (c.maxWidth > 700 ? 4 : 2);
      return GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols, childAspectRatio: c.maxWidth > 700 ? 2.2 : 1.6,
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: cards.map((d) => _KpiCard(data: d)).toList(),
      );
    });
  }

  // ── Analytics Row (Charts left, AI right) ─────────────────
  Widget _buildAnalyticsRow() {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth > 1000) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: _buildLeftColumn()),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildRightColumn()),
        ]);
      }
      return Column(children: [
        Expanded(child: _buildLeftColumn()),
        const SizedBox(height: 20),
        Expanded(child: _buildRightColumn()),
      ]);
    });
  }

  Widget _buildLeftColumn() {
    return Column(children: [
      Expanded(child: _buildChartCard('Fee Collection Trend', Icons.trending_up_rounded, const Color(0xFF3B82F6), _buildLineChart())),
      const SizedBox(height: 12),
      Expanded(child: _buildChartCard('Daily Attendance %', Icons.calendar_today_rounded, const Color(0xFF10B981), _buildBarChart())),
      const SizedBox(height: 12),
      _buildQuickActionsCard(),
    ]);
  }

  Widget _buildRightColumn() {
    return _buildAIStrategicCard();
  }

  Widget _buildChartCard(String title, IconData icon, Color color, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Expanded(child: chart),
      ]),
    );
  }

  Widget _buildLineChart() {
    final trends = (_visualData['feeTrends'] as List?) ?? [];
    if (trends.isEmpty) return _emptyChart('No fee data yet');
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: trends.asMap().entries.map((e) {
          final val = e.value['total'];
          final y = val is String ? double.tryParse(val) ?? 0.0 : (val as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), y);
        }).toList(),
        isCurved: true, color: const Color(0xFF3B82F6), barWidth: 3,
        isStrokeCapRound: true, dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withOpacity(0.15), const Color(0xFF3B82F6).withOpacity(0)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
    ));
  }

  Widget _buildBarChart() {
    final daily = (_visualData['attendanceDaily'] as List?) ?? [];
    if (daily.isEmpty) return _emptyChart('No attendance data yet');
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
      barGroups: daily.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: () { final v = e.value['pct']; return v is String ? double.tryParse(v) ?? 0.0 : (v as num?)?.toDouble() ?? 0.0; }(),
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)],
            begin: Alignment.bottomCenter, end: Alignment.topCenter),
          width: 10, borderRadius: BorderRadius.circular(4),
        ),
      ])).toList(),
    ));
  }

  Widget _emptyChart(String msg) => Center(child: Text(msg,
    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)));

  // ── AI Strategic Card ──────────────────────────────────────
  Widget _buildAIStrategicCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3),
          blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 16),
            SizedBox(width: 8),
            Text('AI Strategic Insights',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF818CF8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('LIVE', style: TextStyle(color: Color(0xFF818CF8), fontSize: 9, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 4),
        const Text('Data-driven growth strategy',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const Divider(color: Color(0xFF334155), height: 20),
        FutureBuilder<String>(
          future: _api.fetchAdminStrategicAdvice(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Color(0xFF818CF8), strokeWidth: 2),
                  SizedBox(height: 10),
                  Text('Analyzing...', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ])));
            }
            if (snap.hasError) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Could not load insights.',
                  style: TextStyle(color: Color(0xFFF87171), fontSize: 12)));
            }
            final text = snap.data ?? '';
            return Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.5),
                      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      h1: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: Color(0xFF818CF8)),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new_rounded, size: 13),
            label: const Text('Full Plan', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF818CF8),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )),
      ]),
    );
  }


  Widget _buildQuickActionsCard() {
    final actions = [
      _ActionData('Manage Users',   Icons.people_alt_rounded,            const Color(0xFF3B82F6), '/admin/users'),
      _ActionData('Add User',       Icons.person_add_rounded,            const Color(0xFF10B981), '/admin/users/new'),
      _ActionData('Fee Setup',      Icons.account_balance_wallet_rounded, const Color(0xFF6366F1), '/admin/fees/structure'),
      _ActionData('Bulk Upload',    Icons.upload_file_rounded,           const Color(0xFFF59E0B), '/admin/users/bulk'),
      _ActionData('Fee Reports',    Icons.bar_chart_rounded,             const Color(0xFF8B5CF6), '/admin/fees/reports'),
    ];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.grid_view_rounded, color: AppTheme.adminAccent, size: 18),
          SizedBox(width: 8),
          Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12,
          children: actions.map((a) => _buildActionTile(a)).toList()),
      ]),
    );
  }

  Widget _buildActionTile(_ActionData a) {
    return InkWell(
      onTap: () => context.go(a.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: a.color.withOpacity(0.05),
          border: Border.all(color: a.color.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: a.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(a.icon, color: a.color, size: 20)),
          const SizedBox(height: 10),
          Text(a.label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }


  // helpers
  String _weekday(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _month(int m)   => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Data models ──────────────────────────────────────────────
class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color, this.sub);
}

class _ActionData {
  final String label, route;
  final IconData icon;
  final Color color;
  const _ActionData(this.label, this.icon, this.color, this.route);
}

// ── KPI Card ─────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 20)),
          Icon(Icons.arrow_outward_rounded, color: data.color.withOpacity(0.5), size: 16),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(data.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(data.sub, style: TextStyle(fontSize: 11, color: data.color)),
        ]),
      ]),
    );
  }
}

// ── Section Header ───────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const _SectionHeader({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
          color: AppTheme.adminPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      ]),
      if (trailing != null) trailing!,
    ]);
  }
}

// ── Refresh Button ───────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 6),
          Text('Refresh', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
