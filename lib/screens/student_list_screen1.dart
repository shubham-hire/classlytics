import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classlytics/core/theme/app_theme.dart';

class StudentListScreen1 extends StatefulWidget {
  const StudentListScreen1({super.key});

  @override
  State<StudentListScreen1> createState() => _StudentListScreenState1();
}

class _StudentListScreenState1 extends State<StudentListScreen1> {

  // 🔥 Dummy Data
  List<Map<String, String>> students = [
    {"name": "Rahul Sharma", "email": "rahul@test.com", "class": "10"},
    {"name": "Priya Patel", "email": "priya@test.com", "class": "9"},
    {"name": "Amit Singh", "email": "amit@test.com", "class": "8"},
  ];

  String searchQuery = "";
  String selectedClass = "All";

  void _deleteStudent(int index) {
    setState(() {
      students.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student Deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {

    // 🔥 FILTER LOGIC
    List<Map<String, String>> filteredStudents = students.where((student) {
      final name = student["name"]!.toLowerCase();
      final matchesSearch = name.contains(searchQuery.toLowerCase());

      final matchesClass =
          selectedClass == "All" || student["class"] == selectedClass;

      return matchesSearch && matchesClass;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Students"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔍 SEARCH
            TextField(
              decoration: const InputDecoration(
                hintText: "Search student...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // 🎯 FILTER
            DropdownButton<String>(
              value: selectedClass,
              isExpanded: true,
              items: ["All", "8", "9", "10"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e == "All" ? "All Classes" : "Class $e"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            // 📋 LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];

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
                              student["name"]!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(student["email"]!),
                            Text("Class: ${student["class"]}"),
                          ],
                        ),

                        // 🔧 ACTIONS
                        Row(
                          children: [

                            // ✏️ EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                context.go('/edit-student', extra: student);
                              },
                            ),

                            // ❌ DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStudent(index),
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