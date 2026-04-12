import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../screens/teacher_dashboard.dart';
import '../../screens/class_list_screen.dart';
import '../../screens/student_list_screen.dart';
import '../../screens/student_detail_screen.dart';

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
      path: '/dashboard',
      builder: (context, state) {
        final role = state.extra as UserRole? ?? UserRole.student;
        return DashboardScreen(userRole: role);
      },
    ),
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboardScreen(),
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
  ],
);
