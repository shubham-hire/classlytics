import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class AddStudentInAdmin extends StatefulWidget {
  const AddStudentInAdmin({super.key});

  @override
  State<AddStudentInAdmin> createState() => _AddStudentInAdminState();
}

class _AddStudentInAdminState extends State<AddStudentInAdmin> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _classController = TextEditingController();

  void _saveStudent() {
    // 🔥 TEMP LOGIC (no backend yet)
    print("Name: ${_nameController.text}");
    print("Email: ${_emailController.text}");
    print("Class: ${_classController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student Added Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Add Student"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Add New Student",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Student Name",
              ),
            ),

            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: "Email",
              ),
            ),

            const SizedBox(height: 16),

            // Class
            TextField(
              controller: _classController,
              decoration: const InputDecoration(
                hintText: "Class",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveStudent,
              child: const Text("Save Student"),
            ),
          ],
          
        ),
      ),
    );
  }
}