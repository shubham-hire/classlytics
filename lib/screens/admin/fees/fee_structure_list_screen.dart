import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/fee_structure.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_shell.dart';

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
    return AdminShell(
      title: 'Fee Structures',
      child: Column(
        children: [
          // ─── CONTROL BAR ───
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Filter Year:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(width: 12),
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
                              selectedColor: AppTheme.adminPrimary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/admin/fees/structure/new');
                    _load();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Structure'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ─── CONTENT ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _structures.isEmpty
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              mainAxisExtent: 420,
                            ),
                            itemCount: _structures.length,
                            itemBuilder: (_, i) => _buildCard(_structures[i]),
                          );
                        },
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
          Icon(Icons.account_balance_wallet_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Fee Structures found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCard(FeeStructure fs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fs.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${fs.className} - ${fs.classSection} | ${fs.academicYear}', 
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('₹${_fmt(fs.totalFee)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.adminAccent)),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _feeItem('Tuition Fee', fs.tuitionFee, Colors.blue),
                  _feeItem('Exam Fee', fs.examFee, Colors.orange),
                  _feeItem('Transport Fee', fs.transportFee, Colors.green),
                  _feeItem('Library Fee', fs.libraryFee, Colors.purple),
                  _feeItem('Sports Fee', fs.sportsFee, Colors.red),
                  _feeItem('Miscellaneous', fs.miscellaneousFee, Colors.grey),
                  const Spacer(),
                  if (fs.dueDate != null)
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('Due: ${fs.dueDate}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await context.push('/admin/fees/structure/edit/${fs.id}');
                      _load();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _delete(fs),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeItem(String label, double amount, Color color) {
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          Text('₹${_fmt(amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
