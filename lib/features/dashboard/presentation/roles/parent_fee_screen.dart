import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'package:classlytics/services/api_service.dart';
import 'package:classlytics/services/auth_store.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ParentFeeScreen extends StatefulWidget {
  const ParentFeeScreen({super.key});

  @override
  State<ParentFeeScreen> createState() => _ParentFeeScreenState();
}

class _ParentFeeScreenState extends State<ParentFeeScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _feeFuture;
  late Razorpay _razorpay;
  String _currentOrderId = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchFees();
  }

  void _fetchFees() {
    final childId = AuthStore.instance.currentUser?['child_id'] ?? '';
    if (childId.isNotEmpty) {
      setState(() {
        _feeFuture = _apiService.fetchFeeStatus(childId.toString());
      });
    } else {
      setState(() {
        _feeFuture = Future.error('No child linked');
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear(); // Removes all listeners
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _apiService.verifyPayment(
        response.orderId ?? _currentOrderId,
        response.paymentId ?? '',
        response.signature ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green));
      _fetchFees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _startPayment(double amount) async {
    final parentId = AuthStore.instance.currentUser?['id'] ?? '';
    final childId = AuthStore.instance.currentUser?['child_id'] ?? '';

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Initiating Payment...')));
      final orderData = await _apiService.createPaymentOrder(parentId.toString(), childId.toString(), amount);
      _currentOrderId = orderData['id'];

      var options = {
        'key': 'rzp_test_SjBzxeHAcNiiEw', // Using the test key from backend config
        'amount': orderData['amount'],
        'name': 'Classlytics Education',
        'order_id': orderData['id'],
        'description': 'Student Fee Payment',
        'prefill': {
          'contact': AuthStore.instance.currentUser?['phone'] ?? '',
          'email': AuthStore.instance.currentUser?['email'] ?? '',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Fee Management', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _feeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading fees: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final data = snapshot.data ?? {};
          final total = data['totalFee'] ?? 0;
          final paid = data['paidAmount'] ?? 0;
          final pending = data['pendingAmount'] ?? 0;
          final dueDateStr = data['dueDate'];
          
          DateTime? dueDate;
          if (dueDateStr != null) {
            try {
              dueDate = DateTime.parse(dueDateStr.toString());
            } catch (_) {}
          }

          final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
          final bool isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && pending > 0;
          final bool dueSoon = dueDate != null && dueDate.difference(DateTime.now()).inDays <= 7 && pending > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOverdue)
                  _buildWarningCard('Payment Overdue!', 'Please clear the pending dues immediately to avoid late fees.', Colors.red)
                else if (dueSoon)
                  _buildWarningCard('Payment Due Soon', 'Just a reminder that the fee is due in ${dueDate!.difference(DateTime.now()).inDays} days.', Colors.orange),

                if (isOverdue || dueSoon) const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.green.shade100, width: 2),
                    boxShadow: [BoxShadow(color: Colors.green.shade50.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Text('Total Outstanding Due', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(formatter.format(pending), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: pending > 0 ? Colors.red : Colors.green)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildFeeItem('Total Fee', formatter.format(total), Colors.blue)),
                          Container(height: 40, width: 1, color: Colors.grey.shade200),
                          Expanded(child: _buildFeeItem('Amount Paid', formatter.format(paid), Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (dueDate != null && pending > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_rounded, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (pending > 0)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _startPayment(double.parse(pending.toString())),
                      icon: const Icon(Icons.payment_rounded, color: Colors.white),
                      label: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                
                if (paid > 0)
                   _buildTransactionRow('Semester 1 Fee Installment', formatter.format(paid), 'Success', 'Earlier'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningCard(String title, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionRow(String title, String amount, String status, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
