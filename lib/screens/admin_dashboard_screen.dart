import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Admin Panel",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔥 Welcome
              const Text(
                "Welcome Admin 🚀",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// 🔥 Announcement Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/announcements');
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text("Announcements"),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 Stats (VERTICAL for mobile)
              _card("Total Students", "120"),
              const SizedBox(height: 12),
              _card("Total Teachers", "10"),

              const SizedBox(height: 20),

              /// 🔥 Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              /// 🔥 Buttons (2 per row)
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context,
                      "Add Student",
                      Icons.person_add,
                      '/add-student',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      context,
                      "Add Teacher",
                      Icons.school,
                      '/add-teacher',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context,
                      "Students",
                      Icons.list,
                      '/students',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      context,
                      "Teachers",
                      Icons.group,
                      '/teachers',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔥 Activity
              const Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _activity("Student Rahul added"),
              _activity("Teacher Sharma removed"),
              _activity("New student registered"),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 CARD (Full width for mobile)
  Widget _card(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 BUTTON
  Widget _actionButton(
      BuildContext context, String text, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () {
        context.go(route);
      },
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  /// 🔹 ACTIVITY TILE
  Widget _activity(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }
}