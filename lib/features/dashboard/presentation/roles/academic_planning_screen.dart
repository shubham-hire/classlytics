import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'leave_request_screen.dart';

class AcademicPlanningScreen extends StatelessWidget {
  const AcademicPlanningScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Academic Planning', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Leave Request Action Block
            _buildLeaveRequestBlock(context),
            const SizedBox(height: 32),

            // Scheduled Lectures (Datewise)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scheduled Lectures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildDateChip('Mon', '12', false),
                  _buildDateChip('Tue', '13', true), // Selected
                  _buildDateChip('Wed', '14', false),
                  _buildDateChip('Thu', '15', false),
                  _buildDateChip('Fri', '16', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLectureCard('Mathematics (Div A)', 'Dr. Sharma', '09:00 AM - 10:00 AM', Colors.blue),
            const SizedBox(height: 12),
            _buildLectureCard('Data Structures', 'Prof. Gupta', '10:15 AM - 11:15 AM', AppTheme.primaryColor),
            const SizedBox(height: 12),
            _buildLectureCard('Physics Lab', 'Mr. Verma', '11:30 AM - 01:30 PM', Colors.orange),
            
            const SizedBox(height: 32),

            // Attendance Diagram (Subject-wise)
            const Text('Subject-wise Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildAttendanceRing(context, 'Math', 78, Colors.blue),
                _buildAttendanceRing(context, 'Physics', 85, Colors.orange),
                _buildAttendanceRing(context, 'Chemistry', 65, Colors.red),
                _buildAttendanceRing(context, 'History', 92, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need a break?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('Apply for a leave of absence.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveRequestScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildLectureCard(String title, String teacher, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.schedule_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('By $teacher • $time', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRing(BuildContext context, String subject, int percentage, Color color) {
    double width = (MediaQuery.of(context).size.width - 40 - 16) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(child: Text('$percentage%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDateChip(String day, String date, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
