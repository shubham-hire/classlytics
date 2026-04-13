import 'package:flutter/material.dart';

class TeacherFeedbackInboxScreen extends StatelessWidget {
  const TeacherFeedbackInboxScreen({super.key});

  final List<Map<String, dynamic>> _feedbacks = const [
    {
      'date': 'Oct 24, 2026',
      'subject': 'Pacing too fast',
      'body': 'The recent chapters in Physics are going too fast. Can we have a revision session?',
      'isAnonymous': false,
      'studentName': 'Amit Verma',
      'class': 'Class 10 A',
      'category': 'Teaching Speed',
    },
    {
      'date': 'Oct 22, 2026',
      'subject': 'More practical examples',
      'body': 'I would appreciate it if we did more practical lab experiments rather than theory.',
      'isAnonymous': true,
      'studentName': 'Anonymous User',
      'class': 'Class 10 A',
      'category': 'Content Delivery',
    },
    {
      'date': 'Oct 19, 2026',
      'subject': 'Great revision class',
      'body': 'The doubt solving session on Sunday was extremely helpful. Thank you!',
      'isAnonymous': true,
      'studentName': 'Anonymous User',
      'class': 'Class 10 B',
      'category': 'Appreciation',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Student Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final fb = _feedbacks[index];
          
          Color catColor = Colors.blue;
          if (fb['category'] == 'Teaching Speed') catColor = Colors.orange;
          if (fb['category'] == 'Appreciation') catColor = Colors.green;
          if (fb['category'] == 'Content Delivery') catColor = Colors.purple;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0,4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(fb['category'], style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Text(fb['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(fb['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(fb['body'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: fb['isAnonymous'] ? Colors.grey.shade200 : const Color(0xFF1E3A8A).withOpacity(0.1),
                      child: Icon(
                        fb['isAnonymous'] ? Icons.person_outline_rounded : Icons.person_rounded, 
                        size: 16, 
                        color: fb['isAnonymous'] ? Colors.grey.shade500 : const Color(0xFF1E3A8A)
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fb['studentName'], 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13, 
                        color: fb['isAnonymous'] ? Colors.grey.shade600 : Colors.black87
                      ),
                    ),
                    if (!fb['isAnonymous']) ...[
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      Text(fb['class'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
