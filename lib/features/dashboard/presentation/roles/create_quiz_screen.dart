import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';
import '../../../../core/theme/app_theme.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _durationMinutes = 30;

  String? _selectedClassId;
  List<dynamic> _classes = [];
  final List<_QuizQuestion> _questions = [];
  bool _isSubmitting = false;

  final ApiService _api = ApiService();
  String get _teacherId => AuthStore.instance.currentUser?['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _questions.add(_QuizQuestion()); // start with one blank question
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final q in _questions) q.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _api.fetchClasses();
      setState(() => _classes = classes);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class.')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question.')));
      return;
    }
    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Question ${i + 1} is empty.')));
        return;
      }
      if (q.correctOption == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select correct answer for Q${i + 1}.')));
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final questionsJson = _questions.map((q) => {
        'question': q.questionCtrl.text.trim(),
        'optionA': q.optionCtrls[0].text.trim(),
        'optionB': q.optionCtrls[1].text.trim(),
        'optionC': q.optionCtrls[2].text.trim(),
        'optionD': q.optionCtrls[3].text.trim(),
        'correctOption': q.correctOption!,
        'marks': 1,
      }).toList();

      await _api.createQuiz(
        classId: _selectedClassId!,
        teacherId: _teacherId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        durationMinutes: _durationMinutes,
        questions: questionsJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Quiz "${_titleCtrl.text}" published with ${_questions.length} questions!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Quiz metadata card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Quiz Title'),
                  const SizedBox(height: 8),
                  _inputField(controller: _titleCtrl, hint: 'e.g. Chapter 5 — Force & Motion',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _label('Description (optional)'),
                  const SizedBox(height: 8),
                  _inputField(controller: _descCtrl, hint: 'Brief instructions for students', maxLines: 2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Class'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedClassId,
                              hint: const Text('Select'),
                              decoration: _inputDecoration(),
                              items: _classes.map<DropdownMenuItem<String>>((c) {
                                return DropdownMenuItem<String>(
                                    value: c['id'] as String,
                                    child: Text('${c['name']} ${c['section']}'));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedClassId = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Duration (mins)'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _durationMinutes,
                              decoration: _inputDecoration(),
                              items: [10, 15, 20, 30, 45, 60, 90]
                                  .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                                  .toList(),
                              onChanged: (v) => setState(() => _durationMinutes = v ?? 30),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Questions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Questions (${_questions.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                TextButton.icon(
                  onPressed: () => setState(() => _questions.add(_QuizQuestion())),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Add Question'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...List.generate(_questions.length, (i) => _buildQuestionCard(i)),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Publish Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    final optionLabels = ['A', 'B', 'C', 'D'];
    final optionColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

    return _card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Q${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
              if (_questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    _questions[index].dispose();
                    _questions.removeAt(index);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: q.questionCtrl,
            maxLines: 2,
            decoration: _inputDecoration(hint: 'Enter question text...'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _label('Options — tap correct answer'),
          const SizedBox(height: 8),
          ...List.generate(4, (oi) {
            final label = optionLabels[oi];
            final color = optionColors[oi];
            final isCorrect = q.correctOption == label;
            return GestureDetector(
              onTap: () => setState(() => q.correctOption = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect ? color.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCorrect ? color : Colors.grey.shade300, width: isCorrect ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isCorrect ? color : Colors.grey.shade200,
                      child: Text(label, style: TextStyle(fontSize: 11, color: isCorrect ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: q.optionCtrls[oi],
                        decoration: const InputDecoration(border: InputBorder.none, hintText: 'Option text...', isDense: true),
                      ),
                    ),
                    if (isCorrect) Icon(Icons.check_circle_rounded, color: color, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets margin = EdgeInsets.zero}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary));

  Widget _inputField({required TextEditingController controller, String? hint, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(hint: hint),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppTheme.backgroundColor,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    isDense: true,
  );
}

class _QuizQuestion {
  final TextEditingController questionCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls = List.generate(4, (_) => TextEditingController());
  String? correctOption;

  void dispose() {
    questionCtrl.dispose();
    for (final c in optionCtrls) c.dispose();
  }
}
