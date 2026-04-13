import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  DateTime _selectedDate = DateTime.now();

  // Mock Lecture Data
  final Map<DateTime, List<Map<String, dynamic>>> _mockLectures = {
    DateTime(2026, 4, 13): [
      {'id': 'L1', 'time': '09:00 AM', 'subject': 'Software Engineering', 'class': 'TE IT A', 'status': 'Completed'},
      {'id': 'L2', 'time': '11:00 AM', 'subject': 'Database Management', 'class': 'TE IT B', 'status': 'Completed'},
      {'id': 'L3', 'time': '02:00 PM', 'subject': 'AI & ML', 'class': 'BE IT A', 'status': 'Pending'},
    ],
    DateTime(2026, 4, 12): [
      {'id': 'L4', 'time': '10:00 AM', 'subject': 'Computer Networks', 'class': 'TE IT A', 'status': 'Completed'},
      {'id': 'L5', 'time': '01:00 PM', 'subject': 'Operating Systems', 'class': 'SE IT B', 'status': 'Completed'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Normalize date for lookup
    final normalizedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final lectures = _mockLectures[normalizedDate] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Attendance Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 8),
          _buildDaySelector(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('Scheduled Lectures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: lectures.isEmpty 
              ? _buildEmptyState()
              : _buildLectureList(lectures),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Quick add for unscheduled/extra lecture
          context.push('/lecture-attendance/EXTRA/C1/Extra%20Lecture');
        },
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Extra Lecture', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      color: const Color(0xFF1E3A8A),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('Select a date to track attendance', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 90,
      color: const Color(0xFF1E3A8A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 7 - index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(color: isSelected ? const Color(0xFF1E3A8A) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(color: isSelected ? const Color(0xFF1E3A8A) : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLectureList(List<Map<String, dynamic>> lectures) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        final isCompleted = lecture['status'] == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                color: isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(lecture['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Class: ${lecture['class']} • ${lecture['time']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCompleted ? 'UPDATE ATTENDANCE' : 'MARK ATTENDANCE',
                    style: TextStyle(
                      color: isCompleted ? Colors.green.shade700 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black26),
            onTap: () {
              context.push('/lecture-attendance/${lecture['id']}/C1/${Uri.encodeComponent(lecture['subject'])}');
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No lectures scheduled for this date', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
