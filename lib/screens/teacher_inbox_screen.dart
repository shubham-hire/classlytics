import 'package:flutter/material.dart';
import 'teacher_chat_screen.dart';

class TeacherInboxScreen extends StatefulWidget {
  const TeacherInboxScreen({super.key});

  @override
  State<TeacherInboxScreen> createState() => _TeacherInboxScreenState();
}

class _TeacherInboxScreenState extends State<TeacherInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock conversations — in real app, fetched from backend
  final List<Map<String, dynamic>> _conversations = [
    {
      'studentId': 'STU001',
      'studentName': 'Rahul Sharma',
      'lastMessage': 'Sir, can you explain the integration topic again?',
      'time': '10:32 AM',
      'unread': 2,
      'class': 'Class 10 A',
    },
    {
      'studentId': 'STU002',
      'studentName': 'Priya Rai',
      'lastMessage': 'Thank you for the notes, sir!',
      'time': 'Yesterday',
      'unread': 0,
      'class': 'Class 10 A',
    },
    {
      'studentId': 'STU003',
      'studentName': 'Amit Verma',
      'lastMessage': 'I will submit the assignment by tonight.',
      'time': 'Mon',
      'unread': 0,
      'class': 'Class 10 A',
    },
    {
      'studentId': 'STU004',
      'studentName': 'Sneha Patil',
      'lastMessage': 'Sir, I was absent due to fever. Please mark me excused.',
      'time': 'Mon',
      'unread': 1,
      'class': 'Class 10 A',
    },
    {
      'studentId': 'STU005',
      'studentName': 'Vikram Seth',
      'lastMessage': 'Understood, sir. I will work on it.',
      'time': 'Last week',
      'unread': 0,
      'class': 'Class 10 A',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) =>
      c['studentName'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  int get _totalUnread => _conversations.fold(0, (sum, c) => sum + (c['unread'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            if (_totalUnread > 0)
              Text('$_totalUnread unread', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Text('No conversations found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final conv = _filtered[index];
                    final hasUnread = (conv['unread'] as int) > 0;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherChatScreen(
                              studentId: conv['studentId'],
                              studentName: conv['studentName'],
                              className: conv['class'],
                            ),
                          ),
                        ).then((_) {
                          // Clear unread on return
                          setState(() {
                            final idx = _conversations.indexWhere((c) => c['studentId'] == conv['studentId']);
                            if (idx != -1) _conversations[idx]['unread'] = 0;
                          });
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: hasUnread
                            ? Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2))
                            : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                                  child: Text(
                                    conv['studentName'][0],
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${conv['unread']}',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Name + message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        conv['studentName'],
                                        style: TextStyle(
                                          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        conv['time'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: hasUnread ? const Color(0xFF1E3A8A) : Colors.grey,
                                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    conv['class'],
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    conv['lastMessage'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasUnread ? Colors.black87 : Colors.grey,
                                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
