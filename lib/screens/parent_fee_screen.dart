import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/auth_store.dart';
import '../../models/student_fee_assignment.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ParentFeeScreen extends StatefulWidget {
  const ParentFeeScreen({super.key});

  @override
  State<ParentFeeScreen> createState() => _ParentFeeScreenState();
}

class _ParentFeeScreenState extends State<ParentFeeScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<StudentFeeAssignment> _assignments = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic>? _categoryFee;
  String? _error;
  
  late Razorpay _razorpay;
  StudentFeeAssignment? _currentProcessingAssignment;

  String get _childId => AuthStore.instance.childId;
  String get _childName => (AuthStore.instance.get('child_name') ?? 'Your Child').toString();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _api.verifyPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
      );
      
      if (_currentProcessingAssignment != null) {
         await _api.recordFeePayment(
           _currentProcessingAssignment!.id,
           _currentProcessingAssignment!.pendingAmount,
           'Online',
           note: 'Razorpay Payment ID: ${response.paymentId}',
         );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet: ${response.walletName}')));
  }

  Future<void> _load() async {
    if (_childId.isEmpty) {
      setState(() { _loading = false; _error = 'No child linked to your account.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.fetchChildFees(_childId);
      Map<String, dynamic>? catFee;
      try {
        catFee = await _api.fetchStudentCategoryFees(childId: _childId);
      } catch (e) {
        // Ignored, might not exist
      }

      setState(() {
        _assignments = (data['assignments'] as List)
            .map((e) => StudentFeeAssignment.fromJson(e))
            .toList();
        _summary = data['summary'] ?? {};
        _categoryFee = catFee?['status'] == 'NO_FEE_ASSIGNED' ? null : catFee;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/parent-dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fee Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(_childName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        if (_categoryFee != null) ...[
                          _buildSectionHeader('Category Fee Structure', 1),
                          const SizedBox(height: 12),
                          _buildCategoryFeeCard(_categoryFee!),
                          const SizedBox(height: 24),
                        ],
                        if (_assignments.isEmpty)
                          _buildNoFees()
                        else ...[
                          _buildSectionHeader('Fee Assignments', _assignments.length),
                          const SizedBox(height: 12),
                          ..._assignments.map(_buildAssignmentCard),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final totalDue = double.tryParse(_summary['totalDue']?.toString() ?? '0') ?? 0;
    final totalPaid = double.tryParse(_summary['totalPaid']?.toString() ?? '0') ?? 0;
    final totalPending = double.tryParse(_summary['totalPending']?.toString() ?? '0') ?? 0;
    final progress = totalDue > 0 ? (totalPaid / totalDue).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // ─── Main Summary Banner ───
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Total Fees Due', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text('₹${_fmt(totalDue)}',
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(progress * 100).toStringAsFixed(0)}% Paid', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('₹${_fmt(totalPaid)} of ₹${_fmt(totalDue)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Paid / Pending Row ───
        Row(
          children: [
            Expanded(child: _miniCard('Paid', totalPaid, const Color(0xFF10B981), Icons.check_circle_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _miniCard('Pending', totalPending, const Color(0xFFEF4444), Icons.pending_actions_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _miniCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('₹${_fmt(amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFeeCard(Map<String, dynamic> fee) {
    final status = fee['status'] ?? 'PENDING';
    final total = double.tryParse(fee['total_amount']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(fee['paid_amount']?.toString() ?? '0') ?? 0;
    final pending = total - paid;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    
    Color statusColor = Colors.orange;
    if (status == 'PAID') statusColor = Colors.green;
    else if (status == 'PARTIAL') statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Academic Category Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text('${fee['department_name'] ?? 'Dept'} · ${fee['year']} · ${fee['category']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountLabel('Total', total, const Color(0xFF64748B)),
                    _amountLabel('Paid', paid, const Color(0xFF10B981)),
                    _amountLabel('Pending', pending, const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          // We could add a "Pay Now" button here specifically for category fees in the future
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(StudentFeeAssignment a) {
    final statusColor = Color(a.statusColor);
    final progress = a.progressPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.structureTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${a.className} - ${a.classSection} · ${a.academicYear}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(a.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),

          // ─── Progress + Amounts ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountLabel('Total', a.totalAmount, const Color(0xFF64748B)),
                    _amountLabel('Paid', a.paidAmount, const Color(0xFF10B981)),
                    _amountLabel('Pending', a.pendingAmount, const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),

          // ─── Fee Breakdown ───
          const Divider(height: 1),
          _buildBreakdown(a),

          // ─── Due Date ───
          if (a.dueDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: 14,
                      color: _isOverdue(a.dueDate!) ? Colors.red : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${a.dueDate}${_isOverdue(a.dueDate!) ? ' — OVERDUE' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOverdue(a.dueDate!) ? Colors.red : const Color(0xFF64748B),
                      fontWeight: _isOverdue(a.dueDate!) ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          
          // ─── Actions ───
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPaymentHistory(a.id),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('History', style: TextStyle(fontSize: 13)),
                ),
                if (a.pendingAmount > 0) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _initiateRazorpayPayment(a),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(StudentFeeAssignment a) {
    // Fee component breakdown is shown via _buildBreakdownFromRaw when raw map available.
    // For the standard model, we return nothing (assignment card already shows totals).
    return const SizedBox.shrink();
  }

  Widget _buildBreakdownFromRaw(Map<String, dynamic> raw) {
    double parse(String k) => double.tryParse(raw[k]?.toString() ?? '0') ?? 0;
    final rows = <_BreakdownItem>[
      _BreakdownItem('Tuition', parse('tuition_fee'), const Color(0xFF3B82F6)),
      _BreakdownItem('Exam', parse('exam_fee'), const Color(0xFFF59E0B)),
      _BreakdownItem('Transport', parse('transport_fee'), const Color(0xFF10B981)),
      _BreakdownItem('Library', parse('library_fee'), const Color(0xFF8B5CF6)),
      _BreakdownItem('Sports', parse('sports_fee'), const Color(0xFFEF4444)),
      _BreakdownItem('Misc', parse('miscellaneous_fee'), const Color(0xFF6B7280)),
    ].where((e) => e.amount > 0).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: rows.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: item.color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${item.label}: ₹${_fmt(item.amount)}',
                  style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget? _breakdownRow(String label, double? amount, Color color) {
    if (amount != null && amount <= 0) return null;
    return null; // Hidden — only shown in raw mode
  }

  Widget _amountLabel(String label, double amount, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      const SizedBox(height: 2),
      Text('₹${_fmt(amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ],
  );

  Widget _buildSectionHeader(String title, int count) => Row(
    children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
      ),
    ],
  );

  Widget _buildNoFees() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.06), shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 16),
        const Text('No Fees Assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('No fee records have been assigned yet.\nContact the school administration.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
        const SizedBox(height: 16),
        Text(_error ?? 'Error loading fees', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Future<void> _initiateRazorpayPayment(StudentFeeAssignment a) async {
    try {
      setState(() => _currentProcessingAssignment = a);
      
      final parentId = AuthStore.instance.get('id')?.toString() ?? 'unknown_parent';
      final studentId = _childId;
      
      // 1. Create order on backend
      final orderResponse = await _api.createPaymentOrder(parentId, studentId, a.pendingAmount);
      
      final orderId = orderResponse['order_id'];
      final keyId = orderResponse['key_id'];
      final amountInPaise = (a.pendingAmount * 100).toInt();

      // 2. Open Razorpay checkout
      var options = {
        'key': keyId,
        'amount': amountInPaise,
        'name': 'Classlytics Education',
        'order_id': orderId,
        'description': 'Fee Payment for ${a.structureTitle}',
        'prefill': {
          'contact': AuthStore.instance.get('phone')?.toString() ?? '9999999999',
          'email': AuthStore.instance.get('email')?.toString() ?? 'parent@example.com'
        },
        'theme': {
          'color': '#1E3A8A'
        }
      };

      _razorpay.open(options);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initiating payment: $e'), backgroundColor: Colors.red));
    }
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

  bool _isOverdue(String dateStr) {
    try {
      return DateTime.parse(dateStr).isBefore(DateTime.now());
    } catch (_) { return false; }
  }

  String _fmt(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(1)}k'
      : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}

class _BreakdownItem {
  final String label;
  final double amount;
  final Color color;
  const _BreakdownItem(this.label, this.amount, this.color);
}
