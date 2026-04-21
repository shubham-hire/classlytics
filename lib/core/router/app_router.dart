import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../screens/ai_teaching_assistant_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../screens/teacher_dashboard.dart';
import '../../screens/class_list_screen.dart';
import '../../screens/student_list_screen.dart';
import '../../screens/student_detail_screen.dart';
import '../../screens/assignments_screen.dart';
import '../../screens/gradebook_screen.dart';
import '../../screens/lecture_attendance_screen.dart';
import '../../screens/teacher_profile_screen.dart';
import '../../screens/leave_management_screen.dart';
import '../../screens/leave_history_screen.dart';
import '../../screens/class_report_screen.dart';
import '../../screens/attendance_management_screen.dart';
import '../../screens/announcements_screen.dart';
import '../../screens/add_student_screen.dart';
import '../../screens/global_student_selection_screen.dart';
import '../../screens/student_dashboard.dart';
import '../../screens/ai_report_generator_screen.dart';
import '../../features/dashboard/presentation/roles/teacher_message_hub_screen.dart';
import '../../screens/student_leave_approval_screen.dart';
import '../../screens/quiz_creator_screen.dart';
import '../../screens/teacher_feedback_inbox_screen.dart';
import '../../screens/digital_library_management_screen.dart';
import '../../screens/timetable_management_screen.dart';
import '../../screens/quiz_results_screen.dart';
import '../../screens/parent_dashboard_screen.dart';
import '../../screens/admin_dashboard_screen.dart';
import 'package:classlytics/screens/student_list_screen1.dart';
import 'package:classlytics/screens/teacher_list_screen.dart';
import 'package:classlytics/screens/announcement_screen.dart';

import '../../screens/add_teacher_screen.dart';
import 'package:classlytics/screens/add_student_in_admin.dart';
import 'package:classlytics/screens/edit_student_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/parent-dashboard',
      builder: (context, state) => const ParentDashboard(),
    ),
    GoRoute(
      path: '/attendance-management',
      builder: (context, state) => const AttendanceManagementScreen(),
    ),
    GoRoute(
      path: '/announcements',
      builder: (context, state) => const AnnouncementsScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        final role = state.extra as UserRole? ?? UserRole.student;
        return DashboardScreen(userRole: role);
      },
    ),
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboard(),
      routes: [
        GoRoute(
          path: 'my-classes',
          builder: (context, state) => const ClassListScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/my-classes',
      builder: (context, state) => const ClassListScreen(),
    ),
    GoRoute(
      path: '/students/:classId',
      builder: (context, state) => StudentListScreen(
        classId: state.pathParameters['classId'] ?? 'unknown',
      ),
    ),
    GoRoute(
      path: '/student-detail/:id/:name',
      builder: (context, state) => StudentDetailScreen(
        studentId: state.pathParameters['id'] ?? 'unknown',
        studentName: state.pathParameters['name'] ?? 'Student',
      ),
    ),
    GoRoute(
      path: '/assignments/:classId',
      builder: (context, state) => AssignmentsScreen(
        classId: state.pathParameters['classId'] ?? 'C1',
      ),
    ),
    GoRoute(
      path: '/gradebook/:classId',
      builder: (context, state) => GradebookScreen(
        classId: state.pathParameters['classId'] ?? 'C1',
      ),
    ),
    GoRoute(
      path: '/lecture-attendance/:lectureId/:classId/:subject',
      builder: (context, state) => LectureAttendanceScreen(
        lectureId: state.pathParameters['lectureId'] ?? 'unknown',
        classId: state.pathParameters['classId'] ?? 'unknown',
        subject: Uri.decodeComponent(state.pathParameters['subject'] ?? 'Software Engineering'),
      ),
    ),
    GoRoute(
      path: '/teacher-profile',
      builder: (context, state) => const TeacherProfileScreen(),
    ),
    GoRoute(
      path: '/teacher-profile/leave',
      builder: (context, state) => const LeaveManagementScreen(),
    ),
    GoRoute(
      path: '/teacher-profile/leave/history',
      builder: (context, state) => const LeaveHistoryScreen(),
    ),
    GoRoute(
      path: '/class-report/:classId/:subject',
      builder: (context, state) => ClassReportScreen(
        classId: state.pathParameters['classId'] ?? 'unknown',
        subject: Uri.decodeComponent(state.pathParameters['subject'] ?? 'General'),
      ),
    ),
    GoRoute(
      path: '/add-student/:classId',
      builder: (context, state) => AddStudentScreen(
        classId: state.pathParameters['classId'] ?? 'GLOBAL',
      ),
    ),
    GoRoute(
      path: '/global-students',
      builder: (context, state) => const GlobalStudentSelectionScreen(),
    ),
    GoRoute(
      path: '/student-dashboard',
      builder: (context, state) => const StudentDashboard(),
    ),
    GoRoute(
      path: '/ai-report/:id/:name',
      builder: (context, state) => AiReportGeneratorScreen(
        studentId: state.pathParameters['id'] ?? 'unknown',
        studentName: state.pathParameters['name'] ?? 'Student',
      ),
    ),
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const AiTeachingAssistantScreen(),
    ),
    GoRoute(
      path: '/teacher-inbox',
      builder: (context, state) => const TeacherMessageHubScreen(),
    ),
    GoRoute(
      path: '/leave-approvals',
      builder: (context, state) => const StudentLeaveApprovalScreen(),
    ),
    GoRoute(
      path: '/quiz-creator',
      builder: (context, state) => const QuizCreatorScreen(),
    ),
    GoRoute(
      path: '/teacher-feedback',
      builder: (context, state) => const TeacherFeedbackInboxScreen(),
    ),
    GoRoute(
      path: '/digital-library',
      builder: (context, state) => const DigitalLibraryManagementScreen(),
    ),
    GoRoute(
      path: '/timetable',
      builder: (context, state) => const TimetableManagementScreen(),
    ),
    GoRoute(
      path: '/quiz-results',
      builder: (context, state) => const QuizResultsScreen(),
    ),
    GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminDashboardScreen(),
),
GoRoute(
  path: '/add-teacher',
  builder: (context, state) => const AddTeacherScreen(),
),
GoRoute(
  path: '/add-student',
  builder: (context, state) => const AddStudentInAdmin(),
),

GoRoute(
  path: '/students',
  builder: (context, state) => const StudentListScreen1(),
),
GoRoute(
  path: '/edit-student',
  builder: (context, state) {
    final student = state.extra as Map<String, String>;
    return EditStudentScreen(student: student);
  },
),
GoRoute(
  path: '/teachers',
  builder: (context, state) => const TeacherListScreen(),
),


  ],

);
