import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AdminAIChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AdminAIChatPanel({super.key, required this.onClose});

  @override
  State<AdminAIChatPanel> createState() => _AdminAIChatPanelState();
}

class _AdminAIChatPanelState extends State<AdminAIChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = ApiService();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'isAi': true,
      'text': 'Hello Administrator! I have analyzed the latest school data. How can I assist you today?',
      'time': DateTime.now(),
    }
  ];
  
  bool _isLoading = false;

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

  void _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'isAi': false, 'text': query, 'time': DateTime.now()});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final answer = await _api.askAdminCommandCenter(query);
      setState(() {
        _messages.add({'isAi': true, 'text': answer, 'time': DateTime.now()});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'isAi': true, 
          'text': "I encountered an error connecting to the intelligence server. Please check your connection.",
          'time': DateTime.now()
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(-5, 0))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.adminPrimary,
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.adminAccent, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Classlytics AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('System Assistant • Online', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Chat Body
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return _buildMessageBubble(m['text'], m['isAi']);
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: LinearProgressIndicator(backgroundColor: Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(AppTheme.adminAccent), minHeight: 2),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about students, fees...',
                      hintStyle: const TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(color: AppTheme.adminPrimary, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAi ? const Color(0xFFF1F5F9) : AppTheme.adminPrimary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 0 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 0),
          ),
        ),
        child: isAi
            ? MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                  strong: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: AppTheme.adminPrimary),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}
