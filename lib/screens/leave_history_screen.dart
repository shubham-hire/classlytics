import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  // Mock data representing last 3 years of leave history
  final List<Map<String, dynamic>> _allLeaves = [
    {"date": "2026-04-10", "type": "Casual Leave", "duration": "1 Day", "status": "Approved"},
    {"date": "2026-03-20", "type": "Sick Leave", "duration": "2 Days", "status": "Approved"},
    {"date": "2026-02-05", "type": "Casual Leave", "duration": "1 Day", "status": "Rejected"},
    {"date": "2025-11-12", "type": "Sick Leave", "duration": "4 Days", "status": "Approved"},
    {"date": "2025-11-03", "type": "Casual Leave", "duration": "1 Day", "status": "Approved"},
    {"date": "2025-08-01", "type": "Casual Leave", "duration": "2 Days", "status": "Approved"},
    {"date": "2024-12-15", "type": "Sick Leave", "duration": "1 Day", "status": "Approved"},
    {"date": "2024-05-10", "type": "Casual Leave", "duration": "3 Days", "status": "Approved"},
    {"date": "2023-10-05", "type": "Sick Leave", "duration": "5 Days", "status": "Approved"},
    {"date": "2023-01-20", "type": "Casual Leave", "duration": "2 Days", "status": "Approved"},
  ];

  Map<String, List<Map<String, dynamic>>> _groupedLeaves = {};

  @override
  void initState() {
    super.initState();
    _groupLeavesMonthWise();
  }

  void _groupLeavesMonthWise() {
    // Sort descending
    _allLeaves.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    for (var leave in _allLeaves) {
      DateTime dt = DateTime.parse(leave['date']);
      String monthYear = DateFormat('MMMM yyyy').format(dt); // e.g. "April 2026"
      
      if (!_groupedLeaves.containsKey(monthYear)) {
        _groupedLeaves[monthYear] = [];
      }
      _groupedLeaves[monthYear]!.add(leave);
    }
  }

  Color _getStatusColor(String status) {
    if (status == "Approved") return Colors.green;
    if (status == "Rejected") return Colors.redAccent;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Leave History (3 Years)', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _groupedLeaves.keys.length,
        itemBuilder: (context, index) {
          String monthYear = _groupedLeaves.keys.elementAt(index);
          List<Map<String, dynamic>> monthLeaves = _groupedLeaves[monthYear]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  monthYear,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                margin: const EdgeInsets.only(bottom: 24),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: monthLeaves.length,
                  separatorBuilder: (context, idx) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final req = monthLeaves[idx];
                    DateTime dt = DateTime.parse(req['date']);
                    String formattedDate = DateFormat('dd MMM').format(dt);
                    Color statusColor = _getStatusColor(req['status']);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(req['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('$formattedDate • ${req['duration']}', style: TextStyle(color: Colors.grey.shade600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          req['status'],
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
