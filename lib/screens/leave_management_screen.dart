import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  // Mock leave balances
  final int sickLeaveTotal = 10;
  final int sickLeaveUsed = 3;
  
  final int casualLeaveTotal = 15;
  final int casualLeaveUsed = 5;

  // Mock leave applications history
  final List<Map<String, dynamic>> _leaveHistory = [
    {
      "date": "10 Apr 2026",
      "type": "Casual Leave",
      "duration": "1 Day",
      "status": "Approved",
      "color": Colors.green
    },
    {
      "date": "20 Mar 2026",
      "type": "Sick Leave",
      "duration": "2 Days",
      "status": "Approved",
      "color": Colors.green
    },
    {
      "date": "05 Feb 2026",
      "type": "Casual Leave",
      "duration": "1 Day",
      "status": "Rejected",
      "color": Colors.redAccent
    }
  ];

  void _applyForLeave() {
    final _formKey = GlobalKey<FormState>();
    DateTime? _startDate;
    DateTime? _endDate;
    final TextEditingController _reasonController = TextEditingController();
    final TextEditingController _startDateController = TextEditingController();
    final TextEditingController _endDateController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apply for Leave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
                        DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave')),
                      ],
                      onChanged: (_) {},
                      validator: (value) => value == null ? 'Please select a leave type' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setModalState(() {
                                  _startDate = date;
                                  _startDateController.text = "${date.day}/${date.month}/${date.year}";
                                });
                              }
                            },
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setModalState(() {
                                  _endDate = date;
                                  _endDateController.text = "${date.day}/${date.month}/${date.year}";
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for leave', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a valid reason' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted successfully!'), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balances
            const Text('Leave Balances (2026)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildBalanceCard('Sick Leave', sickLeaveUsed, sickLeaveTotal, Colors.redAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildBalanceCard('Casual Leave', casualLeaveUsed, casualLeaveTotal, Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Application History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton.icon(
                  onPressed: _applyForLeave,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leaveHistory.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final req = _leaveHistory[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(req['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${req['date']} • ${req['duration']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: req['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        req['status'],
                        style: TextStyle(color: req['color'], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/teacher-profile/leave/history'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Show All History (Last 3 Years)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, int used, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Set fixed height to maintain proper constraints in expanded/row layout without throwing errors.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            '${total - used}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text('out of $total remaining', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
