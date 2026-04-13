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
import '../../screens/teacher_inbox_screen.dart';
import '../../screens/teacher_chat_screen.dart';
import '../../screens/student_leave_approval_screen.dart';

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
      builder: (context, state) => const TeacherInboxScreen(),
    ),
    GoRoute(
      path: '/teacher-chat/:studentId/:studentName/:className',
      builder: (context, state) => TeacherChatScreen(
        studentId: state.pathParameters['studentId'] ?? '',
        studentName: Uri.decodeComponent(state.pathParameters['studentName'] ?? 'Student'),
        className: Uri.decodeComponent(state.pathParameters['className'] ?? 'Class'),
      ),
    ),
    GoRoute(
      path: '/leave-approvals',
      builder: (context, state) => const StudentLeaveApprovalScreen(),
    ),
  ],
);
