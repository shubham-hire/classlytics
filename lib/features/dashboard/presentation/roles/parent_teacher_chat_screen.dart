import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'teacher_message_hub_screen.dart'; // Import ChatScreen from here

class ParentTeacherChatScreen extends StatelessWidget {
  final String teacherId;
  final String teacherName;

  const ParentTeacherChatScreen({
    super.key, 
    required this.teacherId, 
    required this.teacherName
  });

  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      otherUserId: teacherId,
      otherName: teacherName,
    );
  }
}

