import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';

class DetailedAnalyticsScreen extends StatelessWidget {
  const DetailedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detailed Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deep Dive AI Insight
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.psychology_rounded, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Text('AI Performance Diagnostic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Pattern Detected: Your scores in Calculus drop significantly when classes are held before 10 AM. You\'ve also missed 3 consecutive homeworks in this subject. AI predicts a final score of 65% unless immediate action is taken.', style: TextStyle(color: AppTheme.textPrimary, height: 1.5)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Generate Recovery Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Attendance Heatmap mock (using simple grid)
            const Text('Attendance Density', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Last 30 Days', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const Spacer(),
                      _buildLegend(Colors.green, 'Present'),
                      const SizedBox(width: 8),
                      _buildLegend(Colors.red, 'Absent'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(30, (index) {
                      Color boxColor = Colors.green;
                      if (index == 5 || index == 12 || index == 22) boxColor = Colors.red;
                      if (index == 8 || index == 18) boxColor = Colors.orange;
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: boxColor.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                      );
                    }),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
