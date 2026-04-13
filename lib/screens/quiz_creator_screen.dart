import 'package:flutter/material.dart';

class QuizCreatorScreen extends StatefulWidget {
  const QuizCreatorScreen({super.key});

  @override
  State<QuizCreatorScreen> createState() => _QuizCreatorScreenState();
}

class _QuizCreatorScreenState extends State<QuizCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedClass = 'TE IT A';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  final List<Map<String, dynamic>> _questions = [];
  bool _isSubmitting = false;

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'options': ['', '', '', ''],
        'correctIndex': 0,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _publishQuiz() async {
    if (_formKey.currentState!.validate()) {
      if (_questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one question.')));
        return;
      }
      
      setState(() => _isSubmitting = true);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz published successfully!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _publishQuiz,
            child: _isSubmitting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // General Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quiz Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDeco('Quiz Title', Icons.title_rounded),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _subjectController,
                          decoration: _inputDeco('Subject', Icons.book_rounded),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Duration (mins)', Icons.timer_rounded),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: _inputDeco('Target Class', Icons.class_rounded),
                    items: const [
                      DropdownMenuItem(value: 'TE IT A', child: Text('TE IT A')),
                      DropdownMenuItem(value: 'TE IT B', child: Text('TE IT B')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedClass = val);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Questions (${_questions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Question'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A)),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            ...List.generate(_questions.length, (index) => _buildQuestionCard(index)),
            
            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Text('No questions added yet. Tap "Add Question" to start.', style: TextStyle(color: Colors.grey)),
              ),
              
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _removeQuestion(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: q['question'],
            onChanged: (v) => q['question'] = v,
            decoration: _inputDeco('Question Text', Icons.help_outline_rounded),
            validator: (v) => v!.isEmpty ? 'Question cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          
          ...List.generate(4, (optIndex) {
            final isCorrect = q['correctIndex'] == optIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: q['correctIndex'] as int,
                    onChanged: (val) => setState(() => q['correctIndex'] = val!),
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: q['options'][optIndex],
                      onChanged: (v) => q['options'][optIndex] = v,
                      decoration: InputDecoration(
                        hintText: 'Option ${optIndex + 1}',
                        filled: true,
                        fillColor: isCorrect ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: isCorrect ? const BorderSide(color: Colors.green) : BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
