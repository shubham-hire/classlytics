import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
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

  String get _userId =>
      (AuthStore.instance.currentUser?['user_id'] ?? AuthStore.instance.currentUser?['id'] ?? '').toString();

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
        title: const Text('Inbox & Messages',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatBottomSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
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
                (DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime(0)).isAfter(
                    DateTime.tryParse(threads[otherId]!['timestamp'] ?? '') ?? DateTime(0))) {
              threads[otherId] = {
                'otherId': otherId,
                'otherName': otherName,
                'lastMessage': msg['body'] ?? '',
                'timestamp': msg['timestamp'] ?? '',
                'isRead': msg['is_read'] == 1 || msg['is_read'] == true,
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
                  const Text('Tap the button below to start a conversation!',
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

  void _showNewChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: _api.fetchContacts(_userId),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              content = Center(child: Text('Error loading contacts: ${snapshot.error}'));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              content = const Center(child: Text('No contacts found.'));
            } else {
              content = _ContactSelectionSheet(
                contacts: snapshot.data!,
                onSelect: (id, name) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: id.toString(),
                        otherName: name,
                      ),
                    ),
                  ).then((_) => setState(() => _load()));
                },
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: content,
            );
          },
        );
      },
    );
  }
}

class _ContactSelectionSheet extends StatefulWidget {
  final List<dynamic> contacts;
  final void Function(String id, String name) onSelect;

  const _ContactSelectionSheet({required this.contacts, required this.onSelect});

  @override
  State<_ContactSelectionSheet> createState() => _ContactSelectionSheetState();
}

class _ContactSelectionSheetState extends State<_ContactSelectionSheet> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  
  final List<String> _roles = ['All', 'Teacher', 'Student'];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredContacts = widget.contacts.where((contact) {
      final name = (contact['name'] ?? '').toString().toLowerCase();
      final role = (contact['role'] ?? '').toString();
      
      final matchesSearch = name.contains(_searchQuery);
      final matchesRole = _selectedRole == 'All' || role == _selectedRole;
      
      return matchesSearch && matchesRole;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Select Contact',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        
        // Search & Filter UI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRole = role);
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        Expanded(
          child: filteredContacts.isEmpty
              ? const Center(child: Text('No matching contacts found.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final name = contact['name'] ?? 'Unknown';
                    final role = contact['role'] ?? '';
                    final id = contact['id'] ?? '';
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'U',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(role, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      onTap: () => widget.onSelect(id.toString(), name.toString()),
                    );
                  },
                ),
        ),
      ],
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isSending = false;
  bool _isLoading = true;
  bool _isAITyping = false;
  bool _showAISuggestions = false;

  // Dot animation for AI typing indicator
  late AnimationController _dotController;

  static const _aiSenderId = 'classAI';

  List<String> get _aiSuggestions {
    if (_myRole == 'student') {
      return [
        '🎓 Explain a concept',
        '📝 Help with homework',
        '📅 Study tips',
        '💡 Quiz preparation',
      ];
    }
    // Default / Teacher suggestions
    return [
      '🎓 Explain a concept',
      '📊 Analyze @STU001',
      '📅 Create study plan for @STU001',
      '⚠️ Show risk for @STU001',
    ];
  }

  String get _myUserId =>
      (AuthStore.instance.currentUser?['user_id'] ?? AuthStore.instance.currentUser?['id'] ?? '').toString();
  String get _myRole => AuthStore.instance.currentUser?['role']?.toString().toLowerCase() ?? '';
  String get _myName => AuthStore.instance.currentUser?['name'] ?? 'Me';

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _loadMessages();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasAI = _controller.text.toLowerCase().contains('@classai');
    if (hasAI != _showAISuggestions) {
      setState(() => _showAISuggestions = hasAI);
    }
  }

  /// Applies a suggestion pill text, appending after @classAI prefix if not already present.
  void _applySuggestion(String suggestion) {
    // Remove emoji prefix for cleaner prompt
    final clean = suggestion.replaceFirst(RegExp(r'^[^\s]+\s'), '');
    final current = _controller.text.trim();
    final base = current.toLowerCase().contains('@classai') ? current : '@classAI ';
    _controller.text = '$base $clean '.trim();
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final all = await _api.fetchMessages(_myUserId);
      // Include messages with classAI alongside regular conversation messages
      final filtered = all.where((m) {
        final s = (m['sender_id'] ?? '').toString();
        final r = (m['receiver_id'] ?? '').toString();
        return (s == _myUserId && r == widget.otherUserId) ||
            (s == widget.otherUserId && r == _myUserId);
      }).toList();

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

    setState(() {
      _isSending = true;
      _showAISuggestions = false;
    });
    _controller.clear();

    final isAI = text.toLowerCase().contains('@classai');

    // Optimistic UI: add sender's message immediately
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

    if (isAI) {
      setState(() => _isAITyping = true);
    }

    try {
      final result = await _api.sendChatMessage(
        from: _myUserId,
        to: widget.otherUserId,
        body: text,
        role: _myRole,
      );

      if (result['ai'] == true && result['response'] != null) {
        final aiMsg = {
          'sender_id': _aiSenderId,
          'receiver_id': _myUserId,
          'sender_name': 'ClassAI',
          'body': result['response'] as String,
          'timestamp': DateTime.now().toIso8601String(),
          'is_read': true,
        };
        setState(() => _messages.add(aiMsg));
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _messages.removeLast());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
        _isAITyping = false;
      });
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
                            const SizedBox(height: 8),
                            const Text(
                              'Tip: Type @classAI to ask the AI assistant',
                              style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length + (_isAITyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isAITyping && index == _messages.length) {
                            return _buildAITypingIndicator();
                          }
                          final msg = _messages[index];
                          final senderId = (msg['sender_id'] ?? '').toString();
                          String body = msg['body'] ?? '';
                          bool isAI = senderId == _aiSenderId;
                          
                          if (body.startsWith('<!--CLASS_AI-->\n')) {
                            isAI = true;
                            body = body.replaceFirst('<!--CLASS_AI-->\n', '');
                          }

                          // If it's an AI message, it's not "Me" regardless of actual sender_id 
                          // so that the bubble always aligns left
                          final isMe = (senderId == _myUserId) && !isAI;
                          
                          return _buildBubble(
                            body,
                            isMe,
                            _formatTime(msg['timestamp']),
                            isAI: isAI,
                          );
                        },
                      ),
          ),

          // AI Suggestion Pills
          if (_showAISuggestions)
            _buildSuggestionBar(),

          // Input Row
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
                        hintText: 'Message or @classAI ask anything...',
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

  Widget _buildSuggestionBar() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _aiSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _applySuggestion(_aiSuggestions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.12),
                    const Color(0xFF7C3AED).withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                _aiSuggestions[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAITypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _buildAIAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ClassAI is analyzing',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(width: 4),
                  AnimatedBuilder(
                    animation: _dotController,
                    builder: (context, child) {
                      final v = _dotController.value;
                      return Row(
                        children: List.generate(3, (i) {
                          final opacity = ((v + i * 0.33) % 1.0);
                          return Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4 + opacity * 0.6),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('🤖', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, String time, {bool isAI = false}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // AI label
            if (isAI)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAIAvatar(),
                    const SizedBox(width: 6),
                    const Text(
                      'ClassAI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: isAI
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    )
                  : BoxDecoration(
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
                    color: (isMe || isAI) ? Colors.white : AppTheme.textPrimary,
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


