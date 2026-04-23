import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';

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
    return AdminShell(
      title: 'Financial Reports',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HERO SUMMARY ───
                  _buildHeroSummary(),
                  const SizedBox(height: 32),

                  // ─── TWO COLUMN LAYOUT ───
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1000) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildClassBreakdown()),
                            const SizedBox(width: 32),
                            Expanded(flex: 1, child: _buildAIInsightsSection()),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildAIInsightsSection(),
                            const SizedBox(height: 32),
                            _buildClassBreakdown(),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSummary() {
    final s = _reports['summary'] ?? {};
    final expected = double.tryParse(s['expected_revenue']?.toString() ?? '0') ?? 0;
    final collected = double.tryParse(s['collected_revenue']?.toString() ?? '0') ?? 0;
    final pending = double.tryParse(s['pending_revenue']?.toString() ?? '0') ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.adminPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.adminPrimary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ANNUAL REVENUE TARGET', style: TextStyle(color: Colors.white60, letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text('₹${_fmtLarge(expected)}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          Row(
            children: [
              _heroStat('COLLECTED', collected, Colors.greenAccent),
              const SizedBox(width: 48),
              _heroStat('PENDING', pending, Colors.orangeAccent),
              const Spacer(),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${((collected / expected) * 100).toStringAsFixed(1)}% PROGRESS', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: collected / expected,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('₹${_fmtLarge(val)}', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.adminAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.adminAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('AI FINANCIAL INSIGHTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: _api.fetchFeeInsights(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final insights = snapshot.data?['insights'] as String? ?? 'Optimization suggestions pending...';
              final lines = insights.split('\n').where((l) => l.trim().isNotEmpty).toList();
              
              return Column(
                children: lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(line.replaceFirst('•', '').trim(), style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary))),
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

  Widget _buildClassBreakdown() {
    final list = (_reports['by_class'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REVENUE BY CLASS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 180,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            final expected = double.tryParse(c['expected']?.toString() ?? '0') ?? 0;
            final collected = double.tryParse(c['collected']?.toString() ?? '0') ?? 0;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${c['class_name']} - ${c['class_section']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${c['assignments']} Students', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Collected', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text('₹${_fmtLarge(collected)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: expected > 0 ? collected / expected : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.adminPrimary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Target: ₹${_fmtLarge(expected)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _fmtLarge(double v) => v >= 100000 ? '${(v / 100000).toStringAsFixed(2)}L' : (v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0));
}
