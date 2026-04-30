import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/department.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_store.dart';

class ApiService {
  // Use 127.0.0.1 for Web/Desktop, 10.0.2.2 for Emulator, or your local LAN IP for physical device
  static const String _baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://192.168.137.165:3000';

  /// Exposed for screens that need to build multipart requests directly (e.g. file upload)
  static String get baseUrl => _baseUrl;

  // ── JWT Token Storage ──────────────────────────────────────
  static String? _authToken;

  /// Load token from storage on app start
  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    
    // Also load persisted user data
    await AuthStore.instance.loadUser();
    
    if (_authToken != null) {
      debugPrint('ApiService: Token restored from storage.');
    }
  }

  /// Store JWT after login
  static void setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear JWT on logout
  static void clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Returns headers with Authorization for protected routes
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };


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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Store JWT for subsequent protected requests
        if (data['token'] != null) {
          setAuthToken(data['token'] as String);
        }
        return data;
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
      final response = await http.get(uri, headers: _authHeaders);
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
      final response = await http.get(uri, headers: _authHeaders);
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
      final response = await http.get(uri, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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



  Future<void> enrollStudents(String classId, List<String> studentIds) async {
    final url = Uri.parse('$_baseUrl/teacher/enroll');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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
        headers: _authHeaders,
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
    required String classId,
    required String dept,
    required String currentYear,
    required String dob,
    required String rollNo,
    required String category,
    int? departmentId,
  }) async {
    final url = Uri.parse('$_baseUrl/class/create-with-parent');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
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
          'classId': classId,
          'dept': dept,
          'department_id': departmentId,
          'currentYear': currentYear,
          'dob': dob,
          'rollNo': rollNo,
          'category': category,
        }),
      );
      if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to add student with parent');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }



  Future<void> updateStudent(String id, String name, String rollNo, String classId) async {
    final url = Uri.parse('$_baseUrl/class/$id');
    try {
      final response = await http.put(
        url,
        headers: _authHeaders,
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
      final response = await http.get(Uri.parse(query), headers: _authHeaders);
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
        headers: _authHeaders,
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
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(uri, headers: _authHeaders);
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
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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

  Future<void> deleteAssignment(String id) async {
    final url = Uri.parse('$_baseUrl/assignments/$id');
    try {
      final response = await http.delete(url, headers: _authHeaders);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete assignment');
      }
    } catch (e) {
      throw Exception('Error deleting assignment: $e');
    }
  }

  Future<void> editAssignment(String id, String title, String description, String deadline) async {
    final url = Uri.parse('$_baseUrl/assignments/$id');
    try {
      final response = await http.put(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'title': title,
          'description': description,
          'deadline': deadline,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to edit assignment');
      }
    } catch (e) {
      throw Exception('Error editing assignment: $e');
    }
  }


  Future<void> createAssignment(String classId, String title, String description, String deadline, {String? teacherId}) async {
    final url = Uri.parse('$_baseUrl/assignments');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee status');
    } catch (e) {
      throw Exception('Error fetching fee status: $e');
    }
  }

  // ==============================
  // RAZORPAY INTEGRATION
  // ==============================

  Future<Map<String, dynamic>> createPaymentOrder(String parentId, String studentId, double amount) async {
    final url = Uri.parse('$_baseUrl/api/payment/create-order');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'parent_id': parentId,
          'student_id': studentId,
          'amount': amount,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to create payment order: ${response.body}');
    } catch (e) {
      throw Exception('Error creating payment order: $e');
    }
  }

  Future<void> verifyPayment(String orderId, String paymentId, String signature) async {
    final url = Uri.parse('$_baseUrl/api/payment/verify');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  // ==============================
  // DEPARTMENTS
  // ==============================

  Future<List<dynamic>> fetchDepartments() async {
    final url = Uri.parse('$_baseUrl/api/departments');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>? ?? [];
      }
      throw Exception('Failed to load departments');
    } catch (e) {
      throw Exception('Error fetching departments: $e');
    }
  }

  // ==============================
  // CATEGORY FEE STRUCTURES
  // ==============================

  Future<void> createCategoryFeeStructure({
    required int departmentId,
    required String year,
    required String category,
    required double amount,
  }) async {
    final url = Uri.parse('$_baseUrl/api/admin/create-fee-structure');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'department_id': departmentId,
          'year': year,
          'category': category,
          'amount': amount,
        }),
      );
      if (response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create fee structure');
      }
    } catch (e) {
      throw Exception('Error creating fee structure: $e');
    }
  }

  Future<List<dynamic>> fetchCategoryFeeStructures() async {
    final url = Uri.parse('$_baseUrl/api/admin/fee-structures');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['feeStructures'] as List<dynamic>;
      }
      throw Exception('Failed to fetch fee structures');
    } catch (e) {
      throw Exception('Error fetching fee structures: $e');
    }
  }

  Future<Map<String, dynamic>> fetchStudentCategoryFees({String? childId}) async {
    final url = Uri.parse('$_baseUrl/api/student/my-fees${childId != null ? '?childId=$childId' : ''}');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch student fees');
    } catch (e) {
      throw Exception('Error fetching student fees: $e');
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
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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

  /// Send a natural language query to the Admin Command Center AI
  Future<String> askAdminCommandCenter(String query) async {
    final url = Uri.parse('$_baseUrl/ai/admin/command-center');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['answer'] as String;
      }
      throw Exception('Failed to get response from Admin AI');
    } catch (e) {
      debugPrint('ApiService Error [askAdminCommandCenter]: $e');
      throw Exception('Error: $e');
    }
  }

  // --- Draft Announcement via AI ---
  Future<String> draftAdminAnnouncement(String prompt) async {
    final url = Uri.parse('$_baseUrl/ai/admin/draft-announcement');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'prompt': prompt}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['draft'] as String;
      }
      throw Exception('Failed to draft announcement');
    } catch (e) {
      throw Exception('Failed to communicate with AI Drafter: $e');
    }
  }

  // --- Generate AI Student Feedback ---
  Future<Map<String, dynamic>> generateStudentFeedback(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/admin/student-feedback');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'studentId': studentId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to generate feedback');
    } catch (e) {
      throw Exception('Failed to communicate with AI Feedback Generator: $e');
    }
  }

  // --- Phase 3: Proactive Risk Analysis ---
  Future<Map<String, dynamic>> fetchRiskAnalysis() async {
    final url = Uri.parse('$_baseUrl/ai/admin/risk-analysis');
    try {
      final response = await http.get(url, headers: _authHeaders).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch risk analysis');
    } catch (e) {
      throw Exception('Error in Risk Analysis: $e');
    }
  }

  // --- Phase 4: Teacher AI Upgrades ---
  Future<Map<String, dynamic>> fetchClassAnalysis(String classId) async {
    final url = Uri.parse('$_baseUrl/ai/teacher/class-analysis/$classId');
    try {
      final response = await http.get(url, headers: _authHeaders).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch class analysis');
    } catch (e) {
      throw Exception('Error in Class Analysis: $e');
    }
  }

  // ==============================
  // COMMUNICATION
  // ==============================

  Future<void> sendMessage(String to, String body) async {
    final url = Uri.parse('$_baseUrl/communication/messages');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'to': to, 'body': body}),
      );
      if (response.statusCode != 201) throw Exception('Message send failed');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Send a message through the unified AI-aware chat endpoint.
  /// If the message contains @classAI, the backend will:
  ///  - optionally fetch student context (@STU001 mentions)
  ///  - call the NVIDIA LLM
  ///  - save both messages and return { ai: true, response: "..." }
  /// Otherwise returns { ai: false, status: 'sent' }.
  Future<Map<String, dynamic>> sendChatMessage({
    required String from,
    required String to,
    required String body,
    String? role,
  }) async {
    final url = Uri.parse('$_baseUrl/chat/message');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'from': from,
          'to': to,
          'body': body,
          if (role != null) 'role': role,
        }),
      ).timeout(const Duration(seconds: 35));
      if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Chat message failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error sending chat message: $e');
    }
  }

  Future<List<dynamic>> fetchMessages(String userId) async {
    final url = Uri.parse('$_baseUrl/communication/messages/$userId');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return (jsonDecode(response.body)['messages'] as List<dynamic>);
      throw Exception('Failed to fetch messages');
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<List<dynamic>> fetchContacts(String userId) async {
    if (userId.isEmpty) throw Exception('Cannot fetch contacts: User ID is empty. Please re-login.');
    final url = Uri.parse('$_baseUrl/communication/contacts/$userId');
    try {
      final response = await http.get(url, headers: _authHeaders);
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
      if (response.statusCode != 201) throw Exception('Failed to send announcement');
    } catch (e) {
      throw Exception('Error sending announcement: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PARENT ACTIONS
  // ---------------------------------------------------------------------------
  
  Future<void> submitLeaveRequest({
    required String userId,
    required String studentId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final url = Uri.parse('$_baseUrl/parent/leave-request');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'userId': userId,
          'studentId': studentId,
          'startDate': startDate,
          'endDate': endDate,
          'reason': reason,
        }),
      );
      if (response.statusCode != 201) throw Exception('Failed to submit leave request');
    } catch (e) {
      throw Exception('Error submitting leave request: $e');
    }
  }

  Future<List<dynamic>> getLeaveRequests(String studentId) async {
    final url = Uri.parse('$_baseUrl/parent/leave-requests/$studentId');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return (jsonDecode(response.body)['requests'] as List<dynamic>);
      throw Exception('Failed to fetch leave requests');
    } catch (e) {
      throw Exception('Error fetching leave requests: $e');
    }
  }

  Future<String> generateHomeStudyPlan(String studentId) async {
    final url = Uri.parse('$_baseUrl/parent/study-plan');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'studentId': studentId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['plan'] ?? 'No plan generated.';
      }
      throw Exception('Failed to generate study plan');
    } catch (e) {
      throw Exception('Error generating study plan: $e');
    }
  }

  Future<Map<String, dynamic>> fetchChildInfo(String parentId) async {
    final url = Uri.parse('$_baseUrl/parent/child-info/$parentId');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to fetch child info');
    } catch (e) {
      throw Exception('Error fetching child info: $e');
    }
  }

  Future<String> fetchWeeklySummary(String studentId) async {
    final url = Uri.parse('$_baseUrl/ai/parent/weekly-summary/$studentId');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['summary'] ?? 'Summary not available.';
      }
      throw Exception('Failed to fetch weekly summary');
    } catch (e) {
      throw Exception('Error fetching weekly summary: $e');
    }
  }

  Future<List<dynamic>> fetchAnnouncements(String classId) async {
    final url = Uri.parse('$_baseUrl/communication/announcements/$classId');
    try {
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
      final response = await http.get(url, headers: _authHeaders);
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
        headers: _authHeaders,
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
        headers: _authHeaders,
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
        headers: _authHeaders,
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

  // ==============================
  // ADMIN — USER MANAGEMENT
  // ==============================

  /// Fetch admin dashboard stats
  Future<Map<String, dynamic>> fetchAdminStats() async {
    final url = Uri.parse('$_baseUrl/api/admin/stats');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Please log in as Admin.');
      }
      throw Exception('Failed to fetch admin stats');
    } catch (e) {
      throw Exception('Error fetching admin stats: $e');
    }
  }

  /// Fetch all users with optional filters
  Future<Map<String, dynamic>> fetchAdminUsers({
    String? role,
    String? search,
    String? status,
    String? dept,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (role != null && role.isNotEmpty) params['role'] = role;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (dept != null && dept.isNotEmpty) params['dept'] = dept;

    final uri = Uri.parse('$_baseUrl/api/admin/users').replace(queryParameters: params);
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch users');
    } catch (e) {
      throw Exception('Error fetching admin users: $e');
    }
  }

  /// Fetch single user detail
  Future<Map<String, dynamic>> fetchAdminUserById(String id) async {
    final url = Uri.parse('$_baseUrl/api/admin/users/$id');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Create a new user (any role)
  Future<Map<String, dynamic>> createAdminUser(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/api/admin/users');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body)['error'] ?? 'Failed to create user';
      throw Exception(error);
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Update an existing user
  Future<void> updateAdminUser(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/api/admin/users/$id');
    try {
      final response = await http.put(
        url,
        headers: _authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update user';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Delete a user
  Future<void> deleteAdminUser(String id) async {
    final url = Uri.parse('$_baseUrl/api/admin/users/$id');
    try {
      final response = await http.delete(url, headers: _authHeaders);
      if (response.statusCode != 200) throw Exception('Failed to delete user');
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  /// Activate or deactivate a user
  Future<void> toggleAdminUserStatus(String id, bool isActive) async {
    final url = Uri.parse('$_baseUrl/api/admin/users/$id/status');
    try {
      final response = await http.patch(
        url,
        headers: _authHeaders,
        body: jsonEncode({'isActive': isActive}),
      );
      if (response.statusCode != 200) throw Exception('Failed to update user status');
    } catch (e) {
      throw Exception('Error toggling user status: $e');
    }
  }

  /// Bulk create users
  Future<Map<String, dynamic>> bulkCreateAdminUsers(List<Map<String, dynamic>> users) async {
    final url = Uri.parse('$_baseUrl/api/admin/users/bulk');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({'users': users}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      throw Exception('Bulk upload failed');
    } catch (e) {
      throw Exception('Error in bulk upload: $e');
    }
  }

  /// Fetch classes for admin dropdowns
  Future<List<dynamic>> fetchAdminClasses() async {
    final url = Uri.parse('$_baseUrl/api/admin/classes');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch classes');
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }

  /// Fetch students list for parent-child linking
  Future<List<dynamic>> fetchAdminStudentsList() async {
    final url = Uri.parse('$_baseUrl/api/admin/students/list');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch students list');
    } catch (e) {
      throw Exception('Error fetching students list: $e');
    }
  }

  // ==============================
  // FEE STRUCTURE (Admin)
  // ==============================

  Future<List<dynamic>> fetchFeeStructures({String? classId, String? academicYear}) async {
    final params = <String, String>{};
    if (classId != null && classId.isNotEmpty) params['class_id'] = classId;
    if (academicYear != null && academicYear.isNotEmpty) params['academic_year'] = academicYear;
    final uri = Uri.parse('$_baseUrl/api/fees/structure').replace(queryParameters: params.isEmpty ? null : params);
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee structures');
    } catch (e) {
      throw Exception('Error fetching fee structures: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFeeStructureById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/fees/structure/$id');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Fee structure not found');
    } catch (e) {
      throw Exception('Error fetching fee structure: $e');
    }
  }

  Future<Map<String, dynamic>> createFeeStructure(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/fees/structure');
    try {
      final response = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create fee structure');
    } catch (e) {
      throw Exception('Error creating fee structure: $e');
    }
  }

  Future<Map<String, dynamic>> updateFeeStructure(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/fees/structure/$id');
    try {
      final response = await http.put(
        uri,
        headers: _authHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update fee structure');
    } catch (e) {
      throw Exception('Error updating fee structure: $e');
    }
  }

  Future<void> deleteFeeStructure(int id) async {
    final uri = Uri.parse('$_baseUrl/api/fees/structure/$id');
    try {
      final response = await http.delete(uri, headers: _authHeaders);
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete fee structure');
      }
    } catch (e) {
      throw Exception('Error deleting fee structure: $e');
    }
  }

  // ==============================
  // FEE ASSIGNMENTS (Admin - Module 2)
  // ==============================

  Future<List<dynamic>> fetchFeeAssignments({String? classId, String? status, String? studentId}) async {
    final params = <String, String>{};
    if (classId != null && classId.isNotEmpty) params['class_id'] = classId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (studentId != null && studentId.isNotEmpty) params['student_id'] = studentId;
    final uri = Uri.parse('$_baseUrl/api/fees/assignments').replace(queryParameters: params.isEmpty ? null : params);
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee assignments');
    } catch (e) {
      throw Exception('Error fetching fee assignments: $e');
    }
  }

  Future<List<dynamic>> fetchStudentFeeAssignments(String studentId) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments/student/$studentId');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch student fee assignments');
    } catch (e) {
      throw Exception('Error fetching student fee assignments: $e');
    }
  }

  Future<Map<String, dynamic>> assignFeeToStudent(String studentId, int feeStructureId) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments');
    try {
      final response = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode({'student_id': studentId, 'fee_structure_id': feeStructureId}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to assign fee');
    } catch (e) {
      throw Exception('Error assigning fee: $e');
    }
  }

  Future<Map<String, dynamic>> bulkAssignFeeByClass(int feeStructureId) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments/bulk');
    try {
      final response = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode({'fee_structure_id': feeStructureId}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to bulk assign fees');
    } catch (e) {
      throw Exception('Error bulk assigning fees: $e');
    }
  }

  Future<void> removeFeeAssignment(int assignmentId) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments/$assignmentId');
    try {
      final response = await http.delete(uri, headers: _authHeaders);
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to remove assignment');
      }
    } catch (e) {
      throw Exception('Error removing fee assignment: $e');
    }
  }

  Future<List<dynamic>> fetchPaymentHistory(int assignmentId) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments/$assignmentId/payments');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch payment history');
    } catch (e) {
      throw Exception('Error fetching payment history: $e');
    }
  }

  Future<Map<String, dynamic>> recordFeePayment(int assignmentId, double amount, String mode, {String? referenceNo, String? note}) async {
    final uri = Uri.parse('$_baseUrl/api/fees/assignments/$assignmentId/payment');
    try {
      final response = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode({
          'amount': amount,
          'payment_mode': mode,
          'reference_no': referenceNo,
          'note': note,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to record payment');
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFeeReports() async {
    final uri = Uri.parse('$_baseUrl/api/fees/reports');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee reports');
    } catch (e) {
      throw Exception('Error fetching fee reports: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFeeInsights() async {
    final uri = Uri.parse('$_baseUrl/api/fees/insights');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch AI insights');
    } catch (e) {
      throw Exception('Error fetching AI insights: $e');
    }
  }

  // ==============================
  // ADMIN TEACHER MANAGEMENT
  // ==============================

  Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data, {String? imagePath}) async {
    final uri = Uri.parse('$_baseUrl/api/admin/teachers');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders);

    data.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_img', imagePath));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create teacher');
      }
    } catch (e) {
      throw Exception('Error creating teacher: $e');
    }
  }

  Future<List<dynamic>> fetchTeachers() async {
    final uri = Uri.parse('$_baseUrl/api/admin/teachers');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch teachers');
    } catch (e) {
      throw Exception('Error fetching teachers: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTeacherById(String id) async {
    final uri = Uri.parse('$_baseUrl/api/admin/teachers/$id');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch teacher');
    } catch (e) {
      throw Exception('Error fetching teacher: $e');
    }
  }

  Future<Map<String, dynamic>> updateTeacher(String id, Map<String, dynamic> data, {String? imagePath}) async {
    final uri = Uri.parse('$_baseUrl/api/admin/teachers/$id');
    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(_authHeaders);

    data.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_img', imagePath));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) return jsonDecode(response.body);
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update teacher');
    } catch (e) {
      throw Exception('Error updating teacher: $e');
    }
  }

  Future<void> deleteTeacher(String id) async {
    final uri = Uri.parse('$_baseUrl/api/admin/teachers/$id');
    try {
      final response = await http.delete(uri, headers: _authHeaders);
      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete teacher');
      }
    } catch (e) {
      throw Exception('Error deleting teacher: $e');
    }
  }

  // ==============================
  // PARENT FEE DASHBOARD (Module 3)
  // ==============================

  Future<Map<String, dynamic>> fetchChildFees(String studentId) async {
    final uri = Uri.parse('$_baseUrl/parent/fees/$studentId');
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch fee data');
    } catch (e) {
      throw Exception('Error fetching child fees: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAdminVisualAnalytics() async {
    final url = Uri.parse('$_baseUrl/api/admin/visual-analytics');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to fetch visual analytics');
    } catch (e) {
      throw Exception('Error fetching visual analytics: $e');
    }
  }

  Future<String> fetchAdminStrategicAdvice() async {
    final url = Uri.parse('$_baseUrl/ai/admin/strategic-advice');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['advice'] ?? 'Advice not available.';
      }
      throw Exception('Failed to fetch strategic advice');
    } catch (e) {
      throw Exception('Error fetching strategic advice: $e');
    }
  }

  // ==============================
  // SUPER ADMIN
  // ==============================

  Future<Map<String, dynamic>> createDepartmentAdmin({
    required String name,
    required String email,
    String? password,
    required int departmentId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/admin/create-department-admin');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          'department_id': departmentId,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create Department Admin');
  }

  Future<List<dynamic>> getDepartmentAdmins() async {
    final url = Uri.parse('$_baseUrl/api/admin/department-admins');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['departmentAdmins'] as List<dynamic>;
    }
    throw Exception('Failed to fetch Department Admins');
  }

  Future<void> deleteDepartmentAdmin(String id) async {
    final url = Uri.parse('$_baseUrl/api/admin/department-admin/$id');
    final response = await http.delete(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to delete');
    }
  }

  Future<List<Department>> getDepartments() async {
    final url = Uri.parse('$_baseUrl/api/departments');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Department.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch departments');
  }

  // ==============================
  // DEPT ADMIN  // ─── DEPARTMENT ADMIN DASHBOARD / MANAGEMENT ───
  Future<Map<String, dynamic>> getDepartmentAdminProfile() async {
    final url = Uri.parse('$_baseUrl/api/department-admin/profile');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch department admin profile');
  }

  Future<List<dynamic>> deptAdminGetDepartments() async {
    final url = Uri.parse('$_baseUrl/dept-admin/department');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch departments');
  }

  Future<Map<String, dynamic>> deptAdminCreateDepartment(String name) async {
    final url = Uri.parse('$_baseUrl/dept-admin/department');
    final response = await http.post(url,
        headers: _authHeaders, body: jsonEncode({'name': name}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create department');
  }

  // ==============================
  // DEPT ADMIN — CLASSES
  // ==============================

  Future<List<dynamic>> deptAdminGetClasses(int departmentId) async {
    final url = Uri.parse('$_baseUrl/dept-admin/department/$departmentId/classes');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch classes');
  }

  Future<Map<String, dynamic>> deptAdminCreateClass({
    required String name,
    required String section,
    int? departmentId,
    String? teacherId,
  }) async {
    final url = Uri.parse('$_baseUrl/dept-admin/class');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          'name': name,
          'section': section,
          if (departmentId != null) 'department_id': departmentId,
          if (teacherId != null) 'teacher_id': teacherId,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create class');
  }

  // ==============================
  // DEPT ADMIN — DIVISIONS
  // ==============================

  Future<List<dynamic>> deptAdminGetDivisions(String classId) async {
    final url = Uri.parse('$_baseUrl/dept-admin/class/$classId/divisions');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch divisions');
  }

  Future<Map<String, dynamic>> deptAdminCreateDivision({
    required String classId,
    required String divisionName,
  }) async {
    final url = Uri.parse('$_baseUrl/dept-admin/division');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({'class_id': classId, 'division_name': divisionName}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create division');
  }

  // ==============================
  // DEPT ADMIN — STUDENTS
  // ==============================

  Future<List<dynamic>> deptAdminGetStudents(int divisionId) async {
    final url = Uri.parse('$_baseUrl/dept-admin/division/$divisionId/students');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch students');
  }

  Future<Map<String, dynamic>> deptAdminAddStudent({
    required String name,
    required String email,
    required int divisionId,
    String? rollNo,
    String? dob,
    String? currentYear,
  }) async {
    final url = Uri.parse('$_baseUrl/dept-admin/student');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'division_id': divisionId,
          if (rollNo != null) 'roll_no': rollNo,
          if (dob != null) 'dob': dob,
          if (currentYear != null) 'current_year': currentYear,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to add student');
  }

  // ==============================
  // DEPT ADMIN — TIMETABLE
  // ==============================

  Future<List<dynamic>> deptAdminGetTimetable(String classId, String divisionId) async {
    final url = Uri.parse('$_baseUrl/dept-admin/timetable/$classId/$divisionId');
    final response = await http.get(url, headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception('Failed to fetch timetable');
  }

  Future<Map<String, dynamic>> deptAdminCreateTimetableEntry({
    required String classId,
    int? divisionId,
    required String subject,
    String? teacherId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('$_baseUrl/dept-admin/timetable');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          'class_id': classId,
          if (divisionId != null) 'division_id': divisionId,
          'subject': subject,
          if (teacherId != null) 'teacher_id': teacherId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create timetable entry');
  }

  Future<void> deptAdminDeleteTimetableEntry(int id) async {
    final url = Uri.parse('$_baseUrl/dept-admin/timetable/$id');
    final response = await http.delete(url, headers: _authHeaders);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to delete');
    }
  }

  // ==============================
  // DEPT ADMIN — STATISTICS DASHBOARD
  // ==============================

  Future<Map<String, dynamic>> deptAdminGetStats() async {
    final url = Uri.parse('$_baseUrl/api/department-admin/department-stats');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to fetch department stats');
    } catch (e) {
      throw Exception('Error fetching department stats: $e');
    }
  }

  // ==============================
  // DEPT ADMIN — TEACHERS (for dropdowns)
  // ==============================

  Future<List<dynamic>> deptAdminGetTeachers() async {
    final url = Uri.parse('$_baseUrl/api/department-admin/teachers');
    try {
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      throw Exception('Failed to fetch teachers');
    } catch (e) {
      throw Exception('Error fetching teachers: $e');
    }
  }

  // ==============================
  // DEPT ADMIN — STUDENTS BY YEAR
  // ==============================

  Future<List<dynamic>> deptAdminGetStudentsByYear({String? year}) async {
    final params = <String, String>{};
    if (year != null && year.isNotEmpty) params['year'] = year;
    final uri = Uri.parse('$_baseUrl/api/department-admin/students-by-year')
        .replace(queryParameters: params.isEmpty ? null : params);
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      throw Exception('Failed to fetch students by year');
    } catch (e) {
      throw Exception('Error fetching students by year: $e');
    }
  }

  // ==============================
  // DEPT ADMIN — ENHANCED CLASS CREATION
  // ==============================

  Future<Map<String, dynamic>> deptAdminCreateClassEnhanced({
    required String name,
    required String year,
    required String division,
    String? teacherId,
    List<String>? studentIds,
  }) async {
    final url = Uri.parse('$_baseUrl/api/department-admin/create-class');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          'name': name,
          'year': year,
          'division': division,
          if (teacherId != null) 'teacher_id': teacherId,
          if (studentIds != null) 'student_ids': studentIds,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create class');
  }

  // ==============================
  // DEPT ADMIN — ASSIGN ROLL NUMBERS
  // ==============================

  Future<Map<String, dynamic>> deptAdminAssignRollNumbers({
    String? classId,
    int? divisionId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/department-admin/assign-roll-numbers');
    final response = await http.post(url,
        headers: _authHeaders,
        body: jsonEncode({
          if (classId != null) 'class_id': classId,
          if (divisionId != null) 'division_id': divisionId,
        }));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to assign roll numbers');
  }

  // ==============================
  // GLOBAL DEPARTMENTS (Centralized)
  // ==============================



  Future<Map<String, dynamic>> createDepartment(String name) async {
    final url = Uri.parse('$_baseUrl/departments');
    final response = await http.post(url,
        headers: _authHeaders, body: jsonEncode({'name': name}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['error'] ?? 'Failed to create department');
  }
}

