import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiTeachingAssistantScreen extends StatefulWidget {
  const AiTeachingAssistantScreen({super.key});

  @override
  State<AiTeachingAssistantScreen> createState() => _AiTeachingAssistantScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _AiTeachingAssistantScreenState extends State<AiTeachingAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _primaryColor = const Color(0xFF1E3A8A); // Deep Blue

  List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello, Teacher! I'm your AI assistant. How can I lighten your workload today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  
  bool _isTyping = false;

  void _sendMessage([String? textArg]) {
    final text = textArg ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userText) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        String response = "";
        
        if (userText.toLowerCase().contains("draft")) {
          response = "Subject: Update on Academic Progress\n\nDear Parent,\n\nI am writing to share a brief update on your child's recent performance in class. They have been active in their participation, although I recommend setting aside an extra 15 minutes a day for mathematics revision.\n\nPlease let me know if you would like to schedule a call.\n\nWarm regards,\nTeacher.";
        } else if (userText.toLowerCase().contains("attendance")) {
          response = "I've analyzed the recent attendance logs. There's a 7% drop across Class 10-A this week compared to last week. The majority of absences occurred on Thursday. Would you like me to flag the students with below 75% attendance?";
        } else {
          response = "That's a great observation! Based on class historical data, students often struggle with this topic. Consider organizing a 15-minute doubt-clearing session or I can generate a 5-question pop quiz for you to use tomorrow. What do you think?";
        }

        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 150,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickAction(String action) {
    _sendMessage(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Teaching Assistant',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Quick actions horizontally scrollable list
          if (_messages.length < 3)
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickActionChip("Draft a parent email"),
                  const SizedBox(width: 8),
                  _buildQuickActionChip("Analyze attendance"),
                  const SizedBox(width: 8),
                  _buildQuickActionChip("Generate a pop quiz"),
                ],
              ),
            ),

          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          
          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Text('AI is thinking...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask me anything...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: BorderSide(color: _primaryColor.withOpacity(0.2)),
      label: Text(label, style: TextStyle(color: _primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: () => _handleQuickAction(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    bool isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: const Icon(Icons.smart_toy_rounded, size: 20, color: Colors.amber),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            // User Avatar could go here
          ]
        ],
      ),
    );
  }
}
