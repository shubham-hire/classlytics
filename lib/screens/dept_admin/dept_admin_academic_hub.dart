import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import 'dept_admin_manage_classes_screen.dart';
import 'dept_admin_students_screen.dart';

class DeptAdminAcademicHub extends StatefulWidget {
  final int initialTab;
  const DeptAdminAcademicHub({super.key, this.initialTab = 0});

  @override
  State<DeptAdminAcademicHub> createState() => _DeptAdminAcademicHubState();
}

class _DeptAdminAcademicHubState extends State<DeptAdminAcademicHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Academic Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dept-admin'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Classes', icon: Icon(Icons.class_rounded, size: 20)),
            Tab(text: 'Students', icon: Icon(Icons.people_alt_rounded, size: 20)),
            Tab(text: 'Faculty', icon: Icon(Icons.school_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ClassesTab(),
          const _StudentsTab(),
          const _FacultyTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleFabAction(),
        backgroundColor: const Color(0xFF0F9D8C),
        label: Text(_getFabLabel(), style: const TextStyle(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0: return 'New Class';
      case 1: return 'Add Student';
      default: return 'Assign Teacher';
    }
  }

  void _handleFabAction() {
    if (_tabController.index == 0) {
      context.go('/dept-admin/create-class');
    } else if (_tabController.index == 1) {
      // Show global add student dialog or navigate
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use "Create Class" to assign students or visit a specific division.')));
    }
  }
}

class _ClassesTab extends StatelessWidget {
  const _ClassesTab();
  @override
  Widget build(BuildContext context) => const DeptAdminManageClassesScreen();
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab();
  @override
  Widget build(BuildContext context) => const DeptAdminStudentsScreen(); // Needs update to support "Global" view
}

class _FacultyTab extends StatelessWidget {
  const _FacultyTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Faculty List Coming Soon'));
  }
}
