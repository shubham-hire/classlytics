import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_store.dart';

// ─── Chat List Screen ────────────────────────────────────────────────────────
class TeacherMessageHubScreen extends StatefulWidget {
  const TeacherMessageHubScreen({super.key});

  @override
  State<TeacherMessageHubScreen> createState() => _TeacherMessageHubScreenState();
}

class _TeacherMessageHubScreenState extends State<TeacherMessageHubScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _messagesFuture;

  String get _userId => AuthStore.instance.currentUser?['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _messagesFuture = _api.fetchMessages(_userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Teachers & Mentors',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _load()),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? [];

          // Group by the "other person" in the conversation
          final Map<String, Map<String, dynamic>> threads = {};
          for (final msg in messages) {
            final senderId = msg['sender_id'] ?? '';
            final receiverId = msg['receiver_id'] ?? '';
            final otherId = senderId == _userId ? receiverId : senderId;
            final otherName = senderId == _userId
                ? (msg['receiver_name'] ?? 'Teacher')
                : (msg['sender_name'] ?? 'Teacher');

            if (!threads.containsKey(otherId) ||
                (msg['timestamp'] ?? '') > (threads[otherId]!['timestamp'] ?? '')) {
              threads[otherId] = {
                'otherId': otherId,
                'otherName': otherName,
                'lastMessage': msg['body'] ?? '',
                'timestamp': msg['timestamp'] ?? '',
                'isRead': msg['is_read'] ?? true,
                'isMine': senderId == _userId,
              };
            }
          }

          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No messages yet.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Start a conversation with your teacher!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final thread = threads.values.toList()[index];
              return _buildThreadCard(context, thread);
            },
          );
        },
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, Map<String, dynamic> thread) {
    final name = thread['otherName'] as String;
    final lastMsg = thread['lastMessage'] as String;
    final isRead = thread['isRead'] as bool;
    final isMine = thread['isMine'] as bool;

    String timeLabel = '';
    try {
      final ts = DateTime.parse(thread['timestamp'] as String).toLocal();
      final now = DateTime.now();
      final diff = now.difference(ts);
      if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours}h ago';
      } else {
        timeLabel = '${diff.inDays}d ago';
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: thread['otherId'] as String,
              otherName: name,
            ),
          ),
        ).then((_) => setState(() => _load()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isRead ? null : Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary)),
                      Text(timeLabel,
                          style: TextStyle(
                              color: isRead ? AppTheme.textSecondary : AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (isMine)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all_rounded, size: 14, color: AppTheme.textSecondary),
                        ),
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.w600),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppTheme.primaryColor, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual Chat Screen ──────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isSending = false;
  bool _isLoading = true;

  String get _myUserId => AuthStore.instance.currentUser?['id'] ?? '';
  String get _myName => AuthStore.instance.currentUser?['name'] ?? 'Me';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final all = await _api.fetchMessages(_myUserId);
      // Filter to only this conversation
      final filtered = all.where((m) {
        final s = m['sender_id'] ?? '';
        final r = m['receiver_id'] ?? '';
        return (s == _myUserId && r == widget.otherUserId) ||
               (s == widget.otherUserId && r == _myUserId);
      }).toList();

      // Sort oldest first
      filtered.sort((a, b) =>
          (a['timestamp'] ?? '').compareTo(b['timestamp'] ?? ''));

      setState(() {
        _messages = filtered;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    // Optimistic UI: add immediately
    final optimistic = {
      'sender_id': _myUserId,
      'receiver_id': widget.otherUserId,
      'sender_name': _myName,
      'body': text,
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': false,
    };
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      await _api.sendMessage(_myUserId, widget.otherUserId, text);
    } catch (e) {
      // Remove optimistic message and show error
      setState(() => _messages.removeLast());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      setState(() => _isSending = false);
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

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : 'T',
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const Text('Teacher',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Start a conversation with ${widget.otherName}',
                                style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = (msg['sender_id'] ?? '') == _myUserId;
                          return _buildBubble(msg['body'] ?? '', isMe,
                              _formatTime(msg['timestamp']));
                        },
                      ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _isSending
                          ? Colors.grey.shade300
                          : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : _sendMessage,
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

  Widget _buildBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(time,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
