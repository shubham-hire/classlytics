import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';

class AiReportGeneratorScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const AiReportGeneratorScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AiReportGeneratorScreen> createState() => _AiReportGeneratorScreenState();
}

class _AiReportGeneratorScreenState extends State<AiReportGeneratorScreen> {
  bool _isGenerating = false;
  bool _isDone = false;
  String _loadingText = "Initializing AI model...";
  String _generatedReport = "";

  // The primary professional brand color
  final Color _primaryColor = const Color(0xFF1E3A8A);

  void _startGeneration() async {
    setState(() {
      _isGenerating = true;
      _isDone = false;
      _loadingText = "Loading student performance data...";
    });

    final steps = [
      "Analyzing attendance trends...",
      "Evaluating subject scores...",
      "Extracting behavior log insights...",
      "Drafting official narrative report..."
    ];

    for (var step in steps) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _loadingText = step;
        });
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    
    // In the future this gets replaced by NVIDIA LLM API call
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _isDone = true;
        _generatedReport = '''
Performance Summary for ${widget.studentName}

Academic Performance:
${widget.studentName} has demonstrated a solid understanding of core subjects this term. Performance has been consistently stable, particularly highlighting strengths in collaborative tasks and practical assignments. There is room for improvement in deeper theoretical concepts which can be addressed with focused revision.

Attendance & Engagement:
The student maintains regular attendance and participates constructively in classroom discussions. Engagement levels reflect a proactive attitude toward learning.

Behavioral Overview:
Behavior has been commendable. ${widget.studentName} interacts respectfully with peers and staff, contributing to a positive learning environment. No negative incidents have been recorded.

Recommendations:
- Dedicate additional time to reviewing advanced theoretical modules.
- Continue the excellent participation in practical exercises.
- Consider utilizing the school's supplemental resources for upcoming major assessments.
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional gray-white
      appBar: AppBar(
        title: const Text(
          'AI Report Generator',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: _primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Student', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            widget.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text('ID: ${widget.studentId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content Area
              Expanded(
                child: _isGenerating
                    ? _buildLoadingState()
                    : _isDone 
                        ? _buildResultState()
                        : _buildInitialState(),
              ),

              // Action Buttons
              if (!_isGenerating)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _startGeneration,
                    icon: Icon(_isDone ? Icons.refresh : Icons.auto_awesome),
                    label: Text(
                      _isDone ? 'Regenerate Report' : 'Generate Full Report',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_snippet_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Ready to generate report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'The AI will analyze attendance, marks, and behavior data\nto create a cohesive narrative report.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 24),
          Text(
            _loadingText,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Draft', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {},
                      tooltip: 'Copy to Clipboard',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () {},
                      tooltip: 'Export as PDF',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: MarkdownBody(
                data: _generatedReport,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
