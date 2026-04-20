import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:main_app/core/theme/app_theme.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {

  // 🔥 Dummy Data
  List<Map<String, String>> teachers = [
    {"name": "Mr. Sharma", "email": "sharma@test.com", "subject": "Math"},
    {"name": "Mrs. Patel", "email": "patel@test.com", "subject": "Science"},
    {"name": "Mr. Singh", "email": "singh@test.com", "subject": "English"},
  ];

  String searchQuery = "";

  void _deleteTeacher(int index) {
    setState(() {
      teachers.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Teacher Deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {

    // 🔍 FILTER LOGIC
    List<Map<String, String>> filteredTeachers = teachers.where((teacher) {
      final name = teacher["name"]!.toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Teachers"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔍 SEARCH
            TextField(
              decoration: const InputDecoration(
                hintText: "Search teacher...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // 📋 LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredTeachers.length,
                itemBuilder: (context, index) {
                  final teacher = filteredTeachers[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // 🧾 INFO
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher["name"]!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(teacher["email"]!),
                            Text("Subject: ${teacher["subject"]}"),
                          ],
                        ),

                        // 🔧 ACTIONS
                        Row(
                          children: [

                            // ✏️ EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                context.go('/edit-teacher', extra: teacher);
                              },
                            ),

                            // ❌ DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTeacher(index),
                            ),
                          ],
                        ),
                      ],
                    ),
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