import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';

class EditStudentScreen extends StatefulWidget {
  final Map<String, String> student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _classController;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.student["name"]);
    _emailController =
        TextEditingController(text: widget.student["email"]);
    _classController =
        TextEditingController(text: widget.student["class"]);
  }

  void _updateStudent() {
    // 🔥 UI only (no backend yet)
    print("Updated Name: ${_nameController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student Updated")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Edit Student"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Edit Student",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Student Name",
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
              controller: _classController,
              decoration: const InputDecoration(
                hintText: "Class",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _updateStudent,
              child: const Text("Update Student"),
            ),
          ],
        ),
      ),
    );
  }
}