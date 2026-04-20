import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {

  final TextEditingController _controller = TextEditingController();

  List<String> announcements = [];

  void _addAnnouncement() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      announcements.insert(0, _controller.text);
    });

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement Sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Announcements"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ✍️ INPUT
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Write announcement...",
                prefixIcon: Icon(Icons.campaign),
              ),
            ),

            const SizedBox(height: 10),

            // 🚀 SEND BUTTON
            ElevatedButton(
              onPressed: _addAnnouncement,
              child: const Text("Send"),
            ),

            const SizedBox(height: 20),

            // 📋 LIST
            Expanded(
              child: announcements.isEmpty
                  ? const Center(child: Text("No announcements yet"))
                  : ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Text(announcements[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}