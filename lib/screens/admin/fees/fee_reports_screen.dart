import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
class FeeReportsScreen extends StatefulWidget {
  const FeeReportsScreen({super.key});

  @override
  State<FeeReportsScreen> createState() => _FeeReportsScreenState();
}

class _FeeReportsScreenState extends State<FeeReportsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, dynamic> _reports = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.fetchFeeReports();
      setState(() {
        _reports = data;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Fee Reports & Insights', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallSummary(),
                    const SizedBox(height: 16),
                    _buildAIInsights(),
                    const SizedBox(height: 24),
                    const Text('Class-wise Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildClassList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallSummary() {
    final s = _reports['summary'] ?? {};
    final expected = double.tryParse(s['expected_revenue']?.toString() ?? '0') ?? 0;
    final collected = double.tryParse(s['collected_revenue']?.toString() ?? '0') ?? 0;
    final pending = double.tryParse(s['pending_revenue']?.toString() ?? '0') ?? 0;
    final assignments = int.tryParse(s['total_assignments']?.toString() ?? '0') ?? 0;

    final progress = expected > 0 ? (collected / expected).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Expected Revenue', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('₹${_fmt(expected)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toStringAsFixed(1)}% Collected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              Text('₹${_fmt(collected)}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
          
          const Divider(height: 32, color: Colors.white24),
          
          Row(
            children: [
              Expanded(child: _stat('Collected', collected, const Color(0xFF10B981))),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(child: _stat('Pending', pending, const Color(0xFFFCA5A5))),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(child: _stat('Total Students', assignments.toDouble(), Colors.white, isCurrency: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double val, Color color, {bool isCurrency = true}) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(height: 4),
      Text(isCurrency ? '₹${_fmt(val)}' : val.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
    ],
  );

  Widget _buildAIInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('AI Financial Insights', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _api.fetchFeeInsights(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return const Text('Failed to load insights', style: TextStyle(color: Colors.redAccent));
              }
              
              final insights = snapshot.data?['insights'] as String? ?? 'No insights available.';
              final bullets = insights.split('\n').where((s) => s.trim().isNotEmpty).toList();

              return Column(
                children: bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6, right: 10),
                        child: Icon(Icons.circle, size: 6, color: Color(0xFF818CF8)),
                      ),
                      Expanded(child: Text(b.replaceFirst('•', '').trim(), style: const TextStyle(color: Colors.white70, height: 1.4))),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final list = (_reports['by_class'] as List?) ?? [];
    if (list.isEmpty) return const Text('No class assignments yet.');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        final expected = double.tryParse(c['expected']?.toString() ?? '0') ?? 0;
        final collected = double.tryParse(c['collected']?.toString() ?? '0') ?? 0;
        final pending = double.tryParse(c['pending']?.toString() ?? '0') ?? 0;
        final progress = expected > 0 ? (collected / expected).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.school_rounded, size: 16, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 12),
                      Text('${c['class_name']} - ${c['class_section']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  Text('${c['assignments']} Students', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _cStat('Expected', expected, const Color(0xFF1E293B)),
                  _cStat('Collected', collected, const Color(0xFF10B981)),
                  _cStat('Pending', pending, const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cStat(String label, double val, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      Text('₹${_fmt(val)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ],
  );

  String _fmt(double v) => v >= 100000 
    ? '${(v / 100000).toStringAsFixed(2)}L'
    : v >= 1000 
      ? '${(v / 1000).toStringAsFixed(1)}k' 
      : v.toStringAsFixed(0);
}
