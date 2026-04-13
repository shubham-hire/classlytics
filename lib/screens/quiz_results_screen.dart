import 'package:flutter/material.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  // Mock data for quiz results
  final List<Map<String, dynamic>> _quizzes = const [
    {
      'title': 'Physics Mid-Term Quiz',
      'subject': 'Physics',
      'class': 'TE IT A',
      'date': 'Apr 10, 2026',
      'totalStudents': 32,
      'attempted': 30,
      'avgScore': 72.0,
      'highest': 98,
      'lowest': 34,
      'results': [
        {'name': 'Amit Verma', 'score': 98, 'outOf': 100},
        {'name': 'Sneha Patil', 'score': 88, 'outOf': 100},
        {'name': 'Rahul Sharma', 'score': 75, 'outOf': 100},
        {'name': 'Priya Nair', 'score': 68, 'outOf': 100},
        {'name': 'Vikram Seth', 'score': 34, 'outOf': 100},
      ],
    },
    {
      'title': 'Mathematics Quiz — Ch 5',
      'subject': 'Mathematics',
      'class': 'TE IT B',
      'date': 'Apr 08, 2026',
      'totalStudents': 30,
      'attempted': 28,
      'avgScore': 64.0,
      'highest': 95,
      'lowest': 22,
      'results': [
        {'name': 'Riya Mehta', 'score': 95, 'outOf': 100},
        {'name': 'Karan Bose', 'score': 80, 'outOf': 100},
        {'name': 'Ananya Singh', 'score': 58, 'outOf': 100},
        {'name': 'Rohan Das', 'score': 22, 'outOf': 100},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quiz Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return _buildQuizCard(context, quiz);
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Map<String, dynamic> quiz) {
    final avg = quiz['avgScore'] as double;
    final Color avgColor = avg >= 75 ? Colors.green : avg >= 50 ? Colors.orange : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('${quiz['class']} • ${quiz['date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(quiz['subject'], style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Summary Stats Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatPill('Avg Score', '${avg.toInt()}%', avgColor),
                const SizedBox(width: 12),
                _buildStatPill('Highest', '${quiz['highest']}', Colors.green),
                const SizedBox(width: 12),
                _buildStatPill('Lowest', '${quiz['lowest']}', Colors.redAccent),
                const SizedBox(width: 12),
                _buildStatPill('Attempted', '${quiz['attempted']}/${quiz['totalStudents']}', Colors.blue),
              ],
            ),
          ),

          // Score distribution bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Score Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: avg / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: avgColor,
                  ),
                ),
              ],
            ),
          ),

          // Student results list, expandable
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Individual Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
            children: (quiz['results'] as List).map<Widget>((r) {
              final score = r['score'] as int;
              final outOf = r['outOf'] as int;
              final pct = score / outOf;
              final Color bColor = pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: bColor.withOpacity(0.1),
                  child: Text(
                    (r['name'] as String)[0],
                    style: TextStyle(color: bColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: bColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('$score/$outOf', style: TextStyle(color: bColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
