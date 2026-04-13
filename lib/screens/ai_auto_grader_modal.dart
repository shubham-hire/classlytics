import 'package:flutter/material.dart';

class AiAutoGraderModal extends StatefulWidget {
  final Map<String, dynamic>? assignment;
  const AiAutoGraderModal({super.key, this.assignment});

  @override
  State<AiAutoGraderModal> createState() => _AiAutoGraderModalState();
}

class _AiAutoGraderModalState extends State<AiAutoGraderModal> {
  bool _isGrading = false;
  bool _isGraded = false;
  double _suggestedScore = 85.0;

  void _startAiGrading() async {
    setState(() {
      _isGrading = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isGrading = false;
        _isGraded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.assignment?['title'] ?? 'Sample Assignment';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.grading_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Auto-Grader', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Evaluating: $title', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Student Submission
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Submission (Rahul Gupta)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Divider(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                "Gravity is a fundamental interaction which causes mutual attraction between all things with mass or energy. For example, it causes apples to fall from trees and planets to orbit stars.\n\nNewton's law of universal gravitation states that the force is directly proportional to the product of their masses.",
                                style: TextStyle(fontSize: 14, height: 1.6),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Side: AI Rubric & Score
                  Expanded(
                    flex: 1,
                    child: _isGrading
                        ? _buildGradingState()
                        : _isGraded 
                            ? _buildGradedState()
                            : _buildReadyState(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.document_scanner_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Ready to Evaluate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('AI will analyze the text against the rubric.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _startAiGrading,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Grade with AI Rubric'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      ],
    );
  }

  Widget _buildGradingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          const SizedBox(height: 20),
          const Text('Analyzing semantics and factual accuracy...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGradedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('AI Evaluation Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Suggested Score:', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text('${_suggestedScore.toInt()}/100', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 16),
          const Text('Rubric Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildRubricLine('Factual Accuracy', '90%'),
          _buildRubricLine('Clarity', '80%'),
          _buildRubricLine('Completeness', '85%'),
          const SizedBox(height: 16),
          const Text('AI Feedback (for student):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('Good definition of gravity. To achieve full marks, include the formula for Newton\'s law of universal gravitation.', style: TextStyle(fontSize: 13, height: 1.4)),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Score saved to Gradebook!'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Save Score', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRubricLine(String label, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
