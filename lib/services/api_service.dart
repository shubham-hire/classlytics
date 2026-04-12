import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 127.0.0.1 for Web/Desktop and 10.0.2.2 for Android Emulator
  static const String _baseUrl = kIsWeb ? 'http://127.0.0.1:3000' : 'http://10.0.2.2:3000';

  /// Fetches Teacher Dashboard data from the backend
  Future<Map<String, dynamic>> fetchDashboardData() async {
    final url = Uri.parse('$_baseUrl/teacher/dashboard');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Successfully fetched data
        return jsonDecode(response.body);
      } else {
        // Server returned an error
        throw Exception('Failed to load dashboard data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // General error (e.g., network issue)
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  /// Fetches a list of classes for the teacher
  Future<List<dynamic>> fetchClasses() async {
    final url = Uri.parse('$_baseUrl/teacher/classes');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load classes. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching classes: $e');
    }
  }

  /// Fetches the list of students for a specific class
  Future<List<dynamic>> fetchStudents(String classId) async {
    final url = Uri.parse('$_baseUrl/class/$classId/students');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load students. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching students: $e');
    }
  }

  /// Records attendance for a specific student
  Future<void> markAttendance(String studentId, String status) async {
    final url = Uri.parse('$_baseUrl/attendance');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'status': status,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to record attendance. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to post $url');
      print('ApiService Error details: $e');
      throw Exception('Error recording attendance: $e');
    }
  }

  /// Adds marks for a student in a specific subject
  Future<void> addMarks(String studentId, String subject, int score) async {
    final url = Uri.parse('$_baseUrl/marks');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'subject': subject,
          'score': score,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add marks. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to post $url');
      print('ApiService Error details: $e');
      throw Exception('Error adding marks: $e');
    }
  }

  /// Fetches marks history and average score for a student
  Future<Map<String, dynamic>> fetchMarks(String studentId) async {
    final url = Uri.parse('$_baseUrl/marks/$studentId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch marks. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching marks: $e');
    }
  }

  /// Fetches attendance history and percentage for a student
  Future<Map<String, dynamic>> fetchAttendance(String studentId) async {
    final url = Uri.parse('$_baseUrl/attendance/$studentId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch attendance. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching attendance: $e');
    }
  }

  /// Fetches AI-generated insights for a student based on performance and attendance patterns
  Future<List<dynamic>> fetchInsights(String studentId) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/insights');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['insights'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch insights. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching insights: $e');
    }
  }

  /// Fetches student risk level based on attendance and marks
  Future<String> fetchRisk(String studentId) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/risk');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['risk'] as String;
      } else {
        throw Exception('Failed to fetch risk. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching risk: $e');
    }
  }

  /// Fetches actionable suggestions for a student based on overall performance
  Future<List<dynamic>> fetchSuggestions(String studentId) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/suggestions');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['suggestions'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch suggestions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: Failed to fetch $url');
      print('ApiService Error details: $e');
      throw Exception('Error fetching suggestions: $e');
    }
  }

  // ==============================
  // NEW ERP FEATURES
  // ==============================

  // --- Assignments ---
  
  Future<void> createAssignment(String classId, String title, String description, String deadline) async {
    final url = Uri.parse('$_baseUrl/assignments');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classId': classId,
          'title': title,
          'description': description,
          'deadline': deadline,
        }),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create assignment');
      }
    } catch (e) {
      throw Exception('Error creating assignment: $e');
    }
  }

  Future<List<dynamic>> fetchAssignments(String classId) async {
    final url = Uri.parse('$_baseUrl/assignments/$classId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['assignments'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch assignments');
      }
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }

  // --- Behavior Tracking ---

  Future<void> addBehaviorLog(String studentId, String type, String remark) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/behavior');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'remark': remark,
        }),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add behavior log');
      }
    } catch (e) {
      throw Exception('Error adding behavior log: $e');
    }
  }

  Future<List<dynamic>> fetchBehaviorLogs(String studentId) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/behavior');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['behaviorLogs'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch behavior logs');
      }
    } catch (e) {
      throw Exception('Error fetching behavior logs: $e');
    }
  }

  // Fetch Teacher Profile
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/teacher/profile'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
