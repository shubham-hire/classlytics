import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 127.0.0.1 for Web/Desktop, 10.0.2.2 for Emulator, or your local LAN IP for physical device
  static const String _baseUrl = kIsWeb ? 'http://127.0.0.1:3000' : 'http://10.59.178.116:3000';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to post $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to post $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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
      debugPrint('ApiService Error: Failed to fetch $url');
      debugPrint('ApiService Error details: $e');
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

  // --- Class & Student Management ---

  Future<void> addClass(String id, String name, String section) async {
    final url = Uri.parse('$_baseUrl/teacher/classes');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'name': name, 'section': section}),
      );
      if (response.statusCode != 201) throw Exception('Failed to add class');
    } catch (e) {
      throw Exception('Error adding class: $e');
    }
  }

  Future<void> addStudent(String name, String email, String classId, String rollNo) async {
    final url = Uri.parse('$_baseUrl/class/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'classId': classId, 'rollNo': rollNo}),
      );
      if (response.statusCode != 201) throw Exception('Failed to add student');
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }

  Future<void> bulkAddStudents(String classId, List<Map<String, String>> studentList) async {
    final url = Uri.parse('$_baseUrl/class/bulk-add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'classId': classId, 'studentList': studentList}),
      );
      if (response.statusCode != 201) throw Exception('Failed to bulk add students');
    } catch (e) {
      throw Exception('Error bulk adding: $e');
    }
  }

  Future<void> updateStudent(String id, String name, String rollNo, String classId) async {
    final url = Uri.parse('$_baseUrl/class/$id');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'rollNo': rollNo, 'classId': classId}),
      );
      if (response.statusCode != 200) throw Exception('Failed to update student');
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }

  Future<void> addStudentFull({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String country,
    required String state,
    required String district,
    required String city,
    required String classId,
    required String dob,
    required String currentYear,
    required String dept,
  }) async {
    final url = Uri.parse('$_baseUrl/class/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'country': country,
          'state': state,
          'district': district,
          'city': city,
          'classId': classId,
          'dob': dob,
          'currentYear': currentYear,
          'dept': dept,
        }),
      );
      if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to add student');
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }

  Future<List<dynamic>> fetchRegisteredStudents({String? dept, String? year}) async {
    String query = '$_baseUrl/class/registered?';
    if (dept != null) query += 'dept=$dept&';
    if (year != null) query += 'year=$year';
    
    try {
      final response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch global student list');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> enrollStudents(String classId, List<String> studentIds) async {
    final url = Uri.parse('$_baseUrl/teacher/enroll');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'classId': classId, 'studentIds': studentIds}),
      );
      if (response.statusCode != 201) throw Exception('Enrollment failed');
    } catch (e) {
      throw Exception('Error enrolling: $e');
    }
  }

  Future<List<dynamic>> fetchStates() async {
    final response = await http.get(Uri.parse('$_baseUrl/geo/states'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch states');
  }

  Future<List<dynamic>> fetchCities(String stateCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/geo/cities/$stateCode'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch cities');
  }
}
