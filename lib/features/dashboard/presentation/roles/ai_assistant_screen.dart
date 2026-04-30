import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:classlytics/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Homework Help, 1 = Study Planner
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  // Chat message list: {role: 'user'|'ai', text: '...'}
  final List<Map<String, String>> _messages = [];

  // Study plan loaded from backend
  Map<String, dynamic>? _studyPlan;
  bool _loadingPlan = false;

  String get _studentId => AuthStore.instance.studentId;
  String get _studentName =>
      (AuthStore.instance.currentUser?['name'] ?? 'Student').split(' ').first;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text':
          'Hi $_studentName! 👋 I\'m your Classlytics AI assistant. Ask me any academic question — math, science, history, or any subject!',
    });
    _loadStudyPlan();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudyPlan() async {
    setState(() => _loadingPlan = true);
    try {
      final plan = await _api.fetchStudyPlan(_studentId);
      setState(() => _studyPlan = plan);
    } catch (_) {
      setState(() => _studyPlan = null);
    } finally {
      setState(() => _loadingPlan = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _api.askHomeworkHelp(text, studentId: _studentId);

      final answer = result['answer'] ?? 'Sorry, I could not generate a response.';
      setState(() => _messages.add({'role': 'ai', 'text': answer}));
    } catch (e) {
      setState(() => _messages.add({
            'role': 'ai',
            'text':
                '⚠️ Could not reach the AI service. Please check your internet connection and try again.',
          }));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Classlytics AI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Mode Toggle
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Homework Help', Colors.blue),
                  _buildTab(1, 'Study Planner', Colors.orange),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildHomeworkTab() : _buildPlannerTab(),
          ),

          // Input Bar (only for homework tab)
          if (_selectedTab == 0) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, Color activeColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HOMEWORK CHAT TAB ───────────────────────────────────────
  Widget _buildHomeworkTab() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Typing indicator
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(right: 40, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('AI is thinking...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: isUser
              ? _buildUserBubble(msg['text']!)
              : _buildAIBubble(msg['text']!),
        );
      },
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child:
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildAIBubble(String text, {bool isPlanner = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: isPlanner ? Colors.orange.shade50 : Colors.white,
          border: Border.all(
              color: isPlanner ? Colors.orange.shade200 : Colors.grey.shade200),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5),
            strong: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            listBullet: const TextStyle(color: AppTheme.textPrimary),
            h1: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            h2: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            h3: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = image_picker.ImagePicker();
    final picked = await picker.pickImage(source: image_picker.ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final ext = picked.path.split('.').last.toLowerCase();
      final mimeType = 'image/${ext == 'jpg' ? 'jpeg' : ext}';

      setState(() {
        _messages.add({'role': 'user', 'text': '📸 [Attached Image] \nCan you help me with this?'});
        _isLoading = true;
      });
      _scrollToBottom();

      try {
        final result = await _api.askHomeworkHelpWithImage(
          query: 'Please analyze this assignment image and help me understand and solve it step-by-step.',
          studentId: _studentId,
          imageBase64: base64String,
          imageMimeType: mimeType,
        );

        final answer = result['answer'] ?? 'Sorry, I could not generate a response.';
        setState(() => _messages.add({'role': 'ai', 'text': answer}));
      } catch (e) {
        setState(() => _messages.add({
              'role': 'ai',
              'text': '⚠️ Could not reach the AI service to analyze the image.',
            }));
      } finally {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryColor),
              onPressed: _isLoading ? null : _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isLoading
                    ? Colors.grey.shade300
                    : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STUDY PLANNER TAB ──────────────────────────────────────
  Widget _buildPlannerTab() {
    if (_loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studyPlan == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Could not load study plan.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _loadStudyPlan,
                child: const Text('Retry')),
          ],
        ),
      );
    }

    final plan = (_studyPlan!['plan'] as List? ?? []);
    final msg = _studyPlan!['message'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.shade100, shape: BoxShape.circle),
                child: Icon(Icons.lightbulb_rounded,
                    color: Colors.orange.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MarkdownBody(
                  data: msg,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                    strong: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Text('Your Weekly Study Plan',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),

        ...plan.map((day) => _buildPlanDay(day as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildPlanDay(Map<String, dynamic> day) {
    final dayColors = {
      'Monday': Colors.blue,
      'Tuesday': Colors.green,
      'Wednesday': Colors.purple,
      'Thursday': Colors.orange,
      'Friday': Colors.red,
      'Saturday': Colors.teal,
      'Sunday': Colors.indigo,
    };
    final color = dayColors[day['day']] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (day['day'] as String).substring(0, 3),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day['focus'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('${day['activity']} · ${day['duration']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
