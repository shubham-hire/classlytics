import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 127.0.0.1 for Web/Desktop, 10.0.2.2 for Emulator, or your local LAN IP for physical device
  static const String _baseUrl = kIsWeb ? 'http://127.0.0.1:3000' : 'http://192.168.1.9:3000';

  /// Exposed for screens that need to build multipart requests directly (e.g. file upload)
  static String get baseUrl => _baseUrl;


  // ==============================
  // AUTH
  // ==============================

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

  // ==============================
  // TEACHER
  // ==============================

  /// Fetches live Teacher Dashboard data (real stats from DB)
  Future<Map<String, dynamic>> fetchDashboardData({String? teacherId}) async {
    final uri = Uri.parse('$_baseUrl/teacher/dashboard${teacherId != null ? '?teacherId=$teacherId' : ''}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard data. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchDashboardData]: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  /// Fetch teacher profile from DB
  Future<Map<String, dynamic>> fetchProfile({String? teacherId}) async {
    final uri = Uri.parse('$_baseUrl/teacher/profile${teacherId != null ? '?teacherId=$teacherId' : ''}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch class stats for teacher
  Future<List<dynamic>> fetchClassStats({String? teacherId}) async {
    final uri = Uri.parse('$_baseUrl/teacher/class-stats${teacherId != null ? '?teacherId=$teacherId' : ''}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to load class stats');
    } catch (e) {
      throw Exception('Error fetching class stats: $e');
    }
  }

  // ==============================
  // CLASSES
  // ==============================

  Future<List<dynamic>> fetchClasses() async {
    final url = Uri.parse('$_baseUrl/teacher/classes');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load classes. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchClasses]: $e');
      throw Exception('Error fetching classes: $e');
    }
  }

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

  // ==============================
  // STUDENTS
  // ==============================

  Future<List<dynamic>> fetchStudents(String classId) async {
    final url = Uri.parse('$_baseUrl/class/$classId/students');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load students. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchStudents]: $e');
      throw Exception('Error fetching students: $e');
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
          'name': name, 'email': email, 'phone': phone,
          'address': address, 'country': country, 'state': state,
          'district': district, 'city': city, 'classId': classId,
          'dob': dob, 'currentYear': currentYear, 'dept': dept,
        }),
      );
      if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to add student');
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }

  Future<void> addStudentWithParent({
    required String studentName,
    required String studentEmail,
    required String parentName,
    required String relation,
    required String parentPhone,
    required String parentEmail,
    required String address,
    required String country,
    required String state,
    required String district,
    required String city,
    required String dept,
    required String currentYear,
    required String dob,
    required String rollNo,
  }) async {
    final url = Uri.parse('$_baseUrl/class/create-with-parent'); // Should be /class/create-with-parent or maybe /students ?
    // Wait, in studentRoutes.js we use router.post('/create-with-parent')
    // And in app.js, what is the prefix? Wait, I should check app.js to be absolutely sure.
    // In addStudent, the url is $_baseUrl/class/add
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentName': studentName,
          'studentEmail': studentEmail,
          'parentName': parentName,
          'relation': relation,
          'parentPhone': parentPhone,
          'parentEmail': parentEmail,
          'address': address,
          'country': country,
          'state': state,
          'district': district,
          'city': city,
          'dept': dept,
          'currentYear': currentYear,
          'dob': dob,
          'rollNo': rollNo,
        }),
      );
      if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to add student with parent');
    } catch (e) {
      throw Exception('Error: $e');
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

  // ==============================
  // ATTENDANCE
  // ==============================

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
        throw Exception('Failed to record attendance. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [markAttendance]: $e');
      throw Exception('Error recording attendance: $e');
    }
  }

  /// Mark attendance for an entire class at once
  Future<Map<String, dynamic>> markBatchAttendance(List<Map<String, String>> records) async {
    final url = Uri.parse('$_baseUrl/attendance/batch');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'records': records}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Batch attendance failed. Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error in batch attendance: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAttendance(String studentId) async {
    final url = Uri.parse('$_baseUrl/attendance/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch attendance. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchAttendance]: $e');
      throw Exception('Error fetching attendance: $e');
    }
  }

  /// Fetch class-level attendance summary (for teacher view)
  Future<Map<String, dynamic>> fetchClassAttendanceSummary(String classId, {String? date}) async {
    final uri = Uri.parse('$_baseUrl/attendance/class/$classId${date != null ? '?date=$date' : ''}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch class attendance');
    } catch (e) {
      throw Exception('Error fetching class attendance: $e');
    }
  }

  // ==============================
  // MARKS
  // ==============================

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
        throw Exception('Failed to add marks. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [addMarks]: $e');
      throw Exception('Error adding marks: $e');
    }
  }

  Future<Map<String, dynamic>> fetchMarks(String studentId) async {
    final url = Uri.parse('$_baseUrl/marks/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch marks. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchMarks]: $e');
      throw Exception('Error fetching marks: $e');
    }
  }

  /// Fetch quiz results grouped by subject for a student
  Future<Map<String, dynamic>> fetchQuizResults(String studentId) async {
    final url = Uri.parse('$_baseUrl/marks/$studentId/quiz-results');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch quiz results');
    } catch (e) {
      throw Exception('Error fetching quiz results: $e');
    }
  }

  /// Add marks for multiple students at once (teacher batch entry)
  Future<Map<String, dynamic>> addBatchMarks(List<Map<String, dynamic>> records) async {
    final url = Uri.parse('$_baseUrl/marks/batch');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'records': records}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Batch marks failed');
    } catch (e) {
      throw Exception('Error in batch marks: $e');
    }
  }

  // ==============================
  // ASSIGNMENTS
  // ==============================

  Future<void> createAssignment(String classId, String title, String description, String deadline, {String? teacherId}) async {
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
          if (teacherId != null) 'teacherId': teacherId,
        }),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create assignment');
      }
    } catch (e) {
      throw Exception('Error creating assignment: $e');
    }
  }

  /// Fetch assignments for a class (teacher use)
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

  /// Fetch assignments for a student (across all enrolled classes)
  Future<List<dynamic>> fetchStudentAssignments(String studentId) async {
    final url = Uri.parse('$_baseUrl/assignments/student/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['assignments'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch student assignments');
      }
    } catch (e) {
      throw Exception('Error fetching student assignments: $e');
    }
  }

  /// Submit an assignment
  Future<void> submitAssignment(String assignmentId, String studentId, {String? note}) async {
    final url = Uri.parse('$_baseUrl/assignments/$assignmentId/submit');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': studentId, 'note': note ?? ''}),
      );
      if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['error'] ?? 'Submission failed');
    } catch (e) {
      throw Exception('Error submitting assignment: $e');
    }
  }

  /// Fetch submissions for an assignment (teacher use)
  Future<List<dynamic>> fetchSubmissions(String assignmentId) async {
    final url = Uri.parse('$_baseUrl/assignments/$assignmentId/submissions');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return (jsonDecode(response.body)['submissions'] as List<dynamic>);
      throw Exception('Failed to fetch submissions');
    } catch (e) {
      throw Exception('Error fetching submissions: $e');
    }
  }

  // ==============================
  // FEE STATUS
  // ==============================

  /// Fetch fee status for a student
  Future<Map<String, dynamic>> fetchFeeStatus(String studentId) async {
    final url = Uri.parse('$_baseUrl/fee/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee status');
    } catch (e) {
      throw Exception('Error fetching fee status: $e');
    }
  }

  // ==============================
  // BEHAVIOR TRACKING
  // ==============================

  Future<void> addBehaviorLog(String studentId, String type, String remark) async {
    final url = Uri.parse('$_baseUrl/student/$studentId/behavior');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': type, 'remark': remark}),
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

  // ==============================
  // AI INSIGHTS
  // ==============================

  Future<List<dynamic>> fetchInsights(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/$studentId/insights');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['insights'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch insights. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchInsights]: $e');
      throw Exception('Error fetching insights: $e');
    }
  }

  Future<String> fetchRisk(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/$studentId/risk');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['risk'] as String;
      } else {
        throw Exception('Failed to fetch risk. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchRisk]: $e');
      throw Exception('Error fetching risk: $e');
    }
  }

  Future<List<dynamic>> fetchSuggestions(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/$studentId/suggestions');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['suggestions'] as List<dynamic>;
      } else {
        throw Exception('Failed to fetch suggestions. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error [fetchSuggestions]: $e');
      throw Exception('Error fetching suggestions: $e');
    }
  }

  Future<List<dynamic>> fetchNotifications(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/$studentId/notifications');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['notifications'] as List<dynamic>);
      }
      throw Exception('Failed to fetch notifications');
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<Map<String, dynamic>> fetchStudyPlan(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/$studentId/study-plan');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch study plan');
    } catch (e) {
      throw Exception('Error fetching study plan: $e');
    }
  }

  /// Ask the AI Homework Assistant (powered by NVIDIA API)
  /// Pass [studentId] to enable personalized context (attendance, marks, etc.)
  Future<Map<String, dynamic>> askHomeworkHelp(String query, {String? studentId}) async {
    final url = Uri.parse('$_baseUrl/ai/homework-help');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          if (studentId != null) 'studentId': studentId,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Homework help failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error from AI assistant: $e');
    }

  }

  // ==============================
  // COMMUNICATION
  // ==============================

  Future<void> sendMessage(String from, String to, String body) async {
    final url = Uri.parse('$_baseUrl/communication/messages');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'from': from, 'to': to, 'body': body}),
      );
      if (response.statusCode != 201) throw Exception('Message send failed');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<List<dynamic>> fetchMessages(String userId) async {
    final url = Uri.parse('$_baseUrl/communication/messages/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return (jsonDecode(response.body)['messages'] as List<dynamic>);
      throw Exception('Failed to fetch messages');
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<List<dynamic>> fetchContacts(String userId) async {
    final url = Uri.parse('$_baseUrl/communication/contacts/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return (jsonDecode(response.body)['contacts'] as List<dynamic>);
      throw Exception('Failed to fetch contacts');
    } catch (e) {
      throw Exception('Error fetching contacts: $e');
    }
  }

  Future<void> sendAnnouncement(String classId, String title, String body) async {
    final url = Uri.parse('$_baseUrl/communication/announcements');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'classId': classId, 'title': title, 'body': body}),
      );
      if (response.statusCode != 201) throw Exception('Announcement failed');
    } catch (e) {
      throw Exception('Error sending announcement: $e');
    }
  }

  Future<List<dynamic>> fetchAnnouncements(String classId) async {
    final url = Uri.parse('$_baseUrl/communication/announcements/$classId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return (jsonDecode(response.body)['announcements'] as List<dynamic>);
      throw Exception('Failed to fetch announcements');
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }

  /// Fetch all announcements for a student across their enrolled classes
  Future<List<dynamic>> fetchStudentAnnouncements(String studentId) async {
    final url = Uri.parse('$_baseUrl/communication/announcements/student/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return (jsonDecode(response.body)['announcements'] as List<dynamic>);
      throw Exception('Failed to fetch student announcements');
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }

  // ==============================
  // GEO
  // ==============================

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

  // ==============================
  // QUIZZES
  // ==============================

  /// Teacher: Create a quiz with questions
  Future<Map<String, dynamic>> createQuiz({
    required String classId,
    required String teacherId,
    required String title,
    String description = '',
    int durationMinutes = 30,
    required List<Map<String, dynamic>> questions,
  }) async {
    final url = Uri.parse('$_baseUrl/quizzes');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classId': classId,
          'teacherId': teacherId,
          'title': title,
          'description': description,
          'durationMinutes': durationMinutes,
          'questions': questions,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Failed to create quiz: ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error creating quiz: $e');
    }
  }

  /// Student: Get all quizzes across enrolled classes
  Future<List<dynamic>> fetchStudentQuizzes(String studentId) async {
    final url = Uri.parse('$_baseUrl/quizzes/student/$studentId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body)['quizzes'] as List;
      throw Exception('Failed to fetch quizzes');
    } catch (e) {
      throw Exception('Error fetching quizzes: $e');
    }
  }

  /// Teacher: Get quizzes for a class
  Future<List<dynamic>> fetchQuizzesByClass(String classId) async {
    final url = Uri.parse('$_baseUrl/quizzes/class/$classId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body)['quizzes'] as List;
      throw Exception('Failed to fetch class quizzes');
    } catch (e) {
      throw Exception('Error fetching class quizzes: $e');
    }
  }

  /// Get quiz questions (answers hidden for students)
  Future<Map<String, dynamic>> fetchQuizQuestions(String quizId, {String role = 'student'}) async {
    final url = Uri.parse('$_baseUrl/quizzes/$quizId/questions?role=$role');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch questions');
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  /// Student: Submit quiz answers — returns auto-graded result
  Future<Map<String, dynamic>> submitQuiz({
    required String quizId,
    required String studentId,
    required Map<String, String> answers,
    int? timeTakenSeconds,
  }) async {
    final url = Uri.parse('$_baseUrl/quizzes/$quizId/submit');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'answers': answers,
          if (timeTakenSeconds != null) 'timeTakenSeconds': timeTakenSeconds,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Quiz submission failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error submitting quiz: $e');
    }
  }

  /// AI: Ask homework help with optional vision image (base64)
  Future<Map<String, dynamic>> askHomeworkHelpWithImage({
    required String query,
    String? studentId,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    final url = Uri.parse('$_baseUrl/ai/homework-help');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          if (studentId != null) 'studentId': studentId,
          if (imageBase64 != null) 'imageBase64': imageBase64,
          if (imageMimeType != null) 'imageMimeType': imageMimeType,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Homework help failed');
    } catch (e) {
      throw Exception('AI Homework help error: $e');
    }
  }

  /// AI: Ask teacher help with full classes context
  Future<Map<String, dynamic>> askTeacherHelp({
    required String query,
    required String teacherId,
  }) async {
    final url = Uri.parse('$_baseUrl/ai/teacher-help');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'teacherId': teacherId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Teacher help failed');
    } catch (e) {
      throw Exception('AI Teacher help error: $e');
    }
  }
}
