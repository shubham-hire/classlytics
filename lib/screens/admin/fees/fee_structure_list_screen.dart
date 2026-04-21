import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/fee_structure.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class FeeStructureListScreen extends StatefulWidget {
  const FeeStructureListScreen({super.key});

  @override
  State<FeeStructureListScreen> createState() => _FeeStructureListScreenState();
}

class _FeeStructureListScreenState extends State<FeeStructureListScreen> {
  final ApiService _api = ApiService();
  List<FeeStructure> _structures = [];
  bool _loading = true;
  String _filterYear = '';

  final List<String> _academicYears = [
    '', '2024-25', '2025-26', '2026-27',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.fetchFeeStructures(
        academicYear: _filterYear.isEmpty ? null : _filterYear,
      );
      setState(() => _structures = data.map((e) => FeeStructure.fromJson(e)).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(FeeStructure fs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Fee Structure'),
        content: Text('Delete "${fs.title}" for ${fs.className} - ${fs.classSection}?\nThis cannot be undone.'),
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
    if (confirmed != true) return;
    try {
      await _api.deleteFeeStructure(fs.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('Fee Structures', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_ind_rounded),
            tooltip: 'Manage Assignments',
            onPressed: () async {
              await context.push('/admin/fees/assignments');
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Fee Structure',
            onPressed: () async {
              await context.push('/admin/fees/structure/new');
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Year Filter ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Year:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(width: 10),
                  ..._academicYears.map((yr) {
                    final isSelected = _filterYear == yr;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(yr.isEmpty ? 'All' : yr),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _filterYear = yr);
                          _load();
                        },
                        selectedColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ─── Content ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _structures.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _structures.length,
                          itemBuilder: (_, i) => _buildCard(_structures[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 56, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          const Text('No Fee Structures', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Create a fee structure to get started', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push('/admin/fees/structure/new');
              _load();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Fee Structure'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(FeeStructure fs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fs.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _pill(Icons.class_rounded, '${fs.className} - ${fs.classSection}'),
                          const SizedBox(width: 8),
                          _pill(Icons.calendar_today_rounded, fs.academicYear),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${_fmt(fs.totalFee)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ],
            ),
          ),
          // ─── Fee Components ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _feeRow('Tuition Fee', fs.tuitionFee, const Color(0xFF3B82F6)),
                _feeRow('Exam Fee', fs.examFee, const Color(0xFFF59E0B)),
                _feeRow('Transport Fee', fs.transportFee, const Color(0xFF10B981)),
                _feeRow('Library Fee', fs.libraryFee, const Color(0xFF8B5CF6)),
                _feeRow('Sports Fee', fs.sportsFee, const Color(0xFFEF4444)),
                _feeRow('Miscellaneous', fs.miscellaneousFee, const Color(0xFF6B7280)),
                if (fs.dueDate != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text('Due: ${fs.dueDate}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ─── Actions ───
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    onPressed: () async {
                      await context.push('/admin/fees/structure/edit/${fs.id}');
                      _load();
                    },
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () => _delete(fs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _feeRow(String label, double amount, Color color) {
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Text('₹${_fmt(amount)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
