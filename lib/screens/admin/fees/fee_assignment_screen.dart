import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/student_fee_assignment.dart';
import '../../../models/fee_structure.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class FeeAssignmentScreen extends StatefulWidget {
  const FeeAssignmentScreen({super.key});

  @override
  State<FeeAssignmentScreen> createState() => _FeeAssignmentScreenState();
}

class _FeeAssignmentScreenState extends State<FeeAssignmentScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  // Data
  List<StudentFeeAssignment> _assignments = [];
  List<FeeStructure> _structures = [];
  List<dynamic> _classes = [];
  bool _loading = true;

  // Filters
  String _filterStatus = '';
  String _filterClassId = '';

  // Tab
  late TabController _tabController;

  final List<String> _statusOptions = ['', 'Pending', 'Partial', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.fetchFeeAssignments(
          classId: _filterClassId.isEmpty ? null : _filterClassId,
          status: _filterStatus.isEmpty ? null : _filterStatus,
        ),
        _api.fetchFeeStructures(),
        _api.fetchAdminClasses(),
      ]);
      setState(() {
        _assignments = (results[0] as List).map((e) => StudentFeeAssignment.fromJson(e)).toList();
        _structures = (results[1] as List).map((e) => FeeStructure.fromJson(e)).toList();
        _classes = results[2] as List;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bulkAssign(FeeStructure fs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.group_rounded, color: Color(0xFF6366F1)), SizedBox(width: 10), Text('Bulk Assign')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign "${fs.title}" to ALL students in:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Text('${fs.className} - ${fs.classSection} | ${fs.academicYear}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            const Text('Students already assigned will be skipped.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _api.bulkAssignFeeByClass(fs.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Assigned: ${result['assigned']} | Skipped: ${result['skipped']}'),
          backgroundColor: Colors.green,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showAssignIndividual() async {
    String? selectedStudentId;
    int? selectedStructureId;

    // Load students
    List<dynamic> students = [];
    try { students = await _api.fetchAdminStudentsList(); } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, sSet) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Assign Fee to Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              isExpanded: true,
              items: students.map((s) => DropdownMenuItem(
                value: s['id'].toString(),
                child: Text('${s['name']} (${s['id']})', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => sSet(() => selectedStudentId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Select Fee Structure',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              isExpanded: true,
              items: _structures.map((fs) => DropdownMenuItem(
                value: fs.id,
                child: Text('${fs.title} — ${fs.className} (${fs.academicYear})', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => sSet(() => selectedStructureId = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: selectedStudentId != null && selectedStructureId != null
                ? () async {
                    Navigator.pop(ctx);
                    try {
                      await _api.assignFeeToStudent(selectedStudentId!, selectedStructureId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee assigned!'), backgroundColor: Colors.green));
                        _load();
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  }
                : null,
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Future<void> _removeAssignment(StudentFeeAssignment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Assignment?'),
        content: Text('Remove fee assignment for ${a.studentName}?\nThis does NOT delete payment records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.removeFeeAssignment(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Fee Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin/fees/structure')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Assignments', icon: Icon(Icons.list_alt_rounded, size: 18)),
            Tab(text: 'Bulk Assign', icon: Icon(Icons.group_add_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentTab(),
          _buildBulkAssignTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAssignIndividual,
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Assign Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildAssignmentTab() {
    return Column(
      children: [
        // ─── Filters ───
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                ..._statusOptions.map((s) {
                  final isSelected = _filterStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.isEmpty ? 'All' : s, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) { setState(() => _filterStatus = s); _load(); },
                      selectedColor: Color(s.isEmpty ? 0xFF1E293B : (StudentFeeAssignment.statusColors[s] ?? 0xFF1E293B)),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ─── Summary Strip ───
        if (!_loading && _assignments.isNotEmpty) _buildSummaryStrip(),

        // ─── List ───
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _assignments.isEmpty
                  ? _buildEmptyState('No assignments found', 'Assign a fee structure to students to track payments')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _assignments.length,
                        itemBuilder: (_, i) => _buildAssignmentCard(_assignments[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip() {
    final total = _assignments.fold<double>(0, (s, a) => s + a.totalAmount);
    final paid = _assignments.fold<double>(0, (s, a) => s + a.paidAmount);
    final pending = total - paid;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', total, Colors.white),
          _vDivider(),
          _summaryItem('Collected', paid, const Color(0xFF10B981)),
          _vDivider(),
          _summaryItem('Pending', pending, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 2),
      Text('₹${_fmt(amount)}', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
    ],
  );
  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15));

  Widget _buildAssignmentCard(StudentFeeAssignment a) {
    final statusColor = Color(a.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(a.studentName.isNotEmpty ? a.studentName[0].toUpperCase() : '?',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('${a.className} - ${a.classSection} | ${a.academicYear}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(a.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),

          // ─── Progress Bar ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${_fmt(a.paidAmount)} paid', style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w700)),
                    Text('₹${_fmt(a.pendingAmount)} pending', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.progressPercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Total: ₹${_fmt(a.totalAmount)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),

          // ─── Actions ───
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                if (a.dueDate != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('Due: ${a.dueDate}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                  onPressed: () => _removeAssignment(a),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showPaymentHistory(a.id),
                  icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
                  label: const Text('History', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ),
                if (a.pendingAmount > 0) ...[
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () => _showRecordPayment(a),
                    icon: const Icon(Icons.add_card_rounded, size: 14),
                    label: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkAssignTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _structures.isEmpty
            ? _buildEmptyState(
                'No Fee Structures',
                'Create a fee structure first before bulk assigning',
                action: TextButton.icon(
                  onPressed: () => context.go('/admin/fees/structure/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Fee Structure'),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap "Assign All" to assign a fee structure to every student enrolled in its class. Already assigned students will be skipped.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ..._structures.map((fs) => _buildBulkCard(fs)),
                  ],
                ),
              );
  }

  Widget _buildBulkCard(FeeStructure fs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fs.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('${fs.className} - ${fs.classSection}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Text('₹${_fmt(fs.totalFee)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF6366F1))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.calendar_today_rounded, fs.academicYear),
                const SizedBox(width: 8),
                if (fs.dueDate != null) _chip(Icons.event_rounded, 'Due: ${fs.dueDate}'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
                label: const Text('Assign to All Class Students', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _bulkAssign(fs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Future<void> _showRecordPayment(StudentFeeAssignment a) async {
    final amountController = TextEditingController(text: a.pendingAmount.toStringAsFixed(2));
    String paymentMode = 'Cash';
    final formKey = GlobalKey<FormState>();
    bool processing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, bSet) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Student: ${a.studentName} (${a.structureTitle})', style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      if (val > a.pendingAmount) return 'Cannot exceed pending amount (₹${a.pendingAmount})';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Cash', 'Bank Transfer', 'Online', 'Cheque']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => bSet(() => paymentMode = v!),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: processing ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        bSet(() => processing = true);
                        try {
                          await _api.recordFeePayment(a.id, double.parse(amountController.text), paymentMode, note: 'Admin Recorded Payment');
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Recorded successfully!'), backgroundColor: Colors.green));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          bSet(() => processing = false);
                        }
                      },
                      child: processing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showPaymentHistory(int assignmentId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _api.fetchPaymentHistory(assignmentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) return const Center(child: Text('No payments recorded yet.'));
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, i) {
                      final p = payments[i];
                      final date = p['paid_at']?.toString().split('T').first ?? '';
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['payment_mode'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (p['note'] != null && p['note'].toString().isNotEmpty)
                                  Text(p['note'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text('+ ₹${p['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green, fontSize: 15)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String sub, {Widget? action}) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.assignment_rounded, size: 56, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );

  String _fmt(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(1)}k'
      : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}
