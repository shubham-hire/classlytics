import 'package:flutter/material.dart';

class StudentLeaveApprovalScreen extends StatefulWidget {
  const StudentLeaveApprovalScreen({super.key});

  @override
  State<StudentLeaveApprovalScreen> createState() => _StudentLeaveApprovalScreenState();
}

class _StudentLeaveApprovalScreenState extends State<StudentLeaveApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'LR001',
      'studentName': 'Rahul Sharma',
      'class': 'Class 10 A',
      'from': '15 Apr 2026',
      'to': '17 Apr 2026',
      'days': 3,
      'subject': 'Medical Emergency',
      'reason': 'Admitted to hospital due to high fever and dehydration. Medical certificate attached.',
      'attachment': 'medical_cert.pdf',
      'status': 'Pending',
      'submittedAt': '2 hours ago',
    },
    {
      'id': 'LR002',
      'studentName': 'Sneha Patil',
      'class': 'Class 10 A',
      'from': '18 Apr 2026',
      'to': '18 Apr 2026',
      'days': 1,
      'subject': 'Family Function',
      'reason': 'Attending sister\'s wedding ceremony. Kindly grant leave for 1 day.',
      'attachment': null,
      'status': 'Pending',
      'submittedAt': '5 hours ago',
    },
    {
      'id': 'LR003',
      'studentName': 'Amit Verma',
      'class': 'Class 10 A',
      'from': '10 Apr 2026',
      'to': '11 Apr 2026',
      'days': 2,
      'subject': 'Sports Tournament',
      'reason': 'Selected for inter-college cricket tournament being held at district level.',
      'attachment': 'selection_letter.pdf',
      'status': 'Approved',
      'submittedAt': '3 days ago',
    },
    {
      'id': 'LR004',
      'studentName': 'Vikram Seth',
      'class': 'Class 10 A',
      'from': '08 Apr 2026',
      'to': '08 Apr 2026',
      'days': 1,
      'subject': 'Personal Reason',
      'reason': 'Personal work at home.',
      'attachment': null,
      'status': 'Rejected',
      'submittedAt': '5 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterByStatus(String status) =>
      _requests.where((r) => r['status'] == status).toList();

  void _updateStatus(String id, String newStatus) {
    setState(() {
      final idx = _requests.indexWhere((r) => r['id'] == id);
      if (idx != -1) _requests[idx]['status'] = newStatus;
    });

    final color = newStatus == 'Approved' ? Colors.green : Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request $newStatus successfully.'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filterByStatus('Pending');
    final approved = _filterByStatus('Approved');
    final rejected = _filterByStatus('Rejected');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Leave Approvals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(pending, showActions: true),
          _buildList(approved, showActions: false),
          _buildList(rejected, showActions: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> requests, {required bool showActions}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              showActions ? 'No pending leave requests' : 'Nothing here yet',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildCard(requests[index], showActions: showActions),
    );
  }

  Widget _buildCard(Map<String, dynamic> req, {required bool showActions}) {
    final status = req['status'] as String;
    Color statusColor = Colors.orange;
    if (status == 'Approved') statusColor = Colors.green;
    if (status == 'Rejected') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                    child: Text(
                      req['studentName'][0],
                      style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['studentName'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(req['class'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Duration
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${req['from']} → ${req['to']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${req['days']} day(s)', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subject
          Text(req['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 6),

          // Reason
          Text(req['reason'], style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),

          // Attachment + Time row
          Row(
            children: [
              if (req['attachment'] != null) ...[
                const Icon(Icons.attach_file_rounded, size: 14, color: Colors.blueAccent),
                const SizedBox(width: 4),
                Text(req['attachment'], style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Submitted ${req['submittedAt']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),

          // Approve / Reject actions
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(req['id'], 'Rejected'),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(req['id'], 'Approved'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
