import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();

  void _saveTeacher() {
    // 🔥 For now just print (later connect backend)
    print("Name: ${_nameController.text}");
    print("Email: ${_emailController.text}");
    print("Subject: ${_subjectController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Teacher Added Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Add Teacher"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Add New Teacher",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Teacher Name",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: "Email",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: "Subject",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveTeacher,
              child: const Text("Save Teacher"),
            ),
          ],
        ),
      ),
    );
  }
}