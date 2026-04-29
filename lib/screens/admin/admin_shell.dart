import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'command_center_dialog.dart';
import 'admin_ai_chat_panel.dart';
import '../../services/api_service.dart';
import '../../services/auth_store.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  final String title;

  const AdminShell({
    super.key,
    required this.child,
    this.title = 'Admin Panel',
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _isSidebarCollapsed = false;
  bool _isChatOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isTablet = MediaQuery.of(context).size.width >= 700 && MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: AppTheme.adminBackground,
      drawer: !isDesktop ? _buildSidebar(context, isDrawer: true) : null,
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop)
                _buildSidebar(context),
              
              Expanded(
                child: Column(
                  children: [
                    _buildTopbar(context, !isDesktop),
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Sliding AI Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isChatOpen ? 0 : -400,
            top: 0,
            bottom: 0,
            child: AdminAIChatPanel(
              onClose: () => setState(() => _isChatOpen = false),
            ),
          ),
        ],
      ),
      floatingActionButton: _isChatOpen 
        ? null 
        : FloatingActionButton(
            onPressed: () => setState(() => _isChatOpen = true),
            backgroundColor: AppTheme.adminAccent,
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
    );
  }

  Widget _buildTopbar(BuildContext context, bool showMenuButton) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.adminPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.adminPrimary,
            ),
          ),
          
          const Spacer(),
          
          // Global Search Bar
          if (MediaQuery.of(context).size.width > 800)
            Container(
              width: 350,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search students, teachers, records...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  // TODO: Implement Global Search Logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $value')),
                  );
                },
              ),
            ),
          
          if (MediaQuery.of(context).size.width <= 800)
            const Spacer(),
          
          const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary),
          const SizedBox(width: 20),
          
          // User Profile
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.adminAccent,
                child: Text('A', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              if (MediaQuery.of(context).size.width > 600) ...[
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Super Admin', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    final sidebarWidth = _isSidebarCollapsed && !isDrawer ? 80.0 : 260.0;
    
    return Container(
      width: sidebarWidth,
      height: double.infinity,
      color: AppTheme.adminPrimary,
      child: Column(
        children: [
          // Logo Section
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppTheme.adminAccent, size: 32),
                if (!_isSidebarCollapsed || isDrawer) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Classlytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', '/admin', context),
                _buildNavItem(Icons.people_alt_rounded, 'Users', '/admin/users', context),
                _buildNavItem(Icons.badge_rounded, 'Teacher Module', '/admin/teachers', context),
                _buildNavItem(Icons.account_balance_wallet_rounded, 'Class Financials', '/admin/fees/structure', context),
                _buildNavItem(Icons.category_rounded, 'Category Fees', '/admin/category-fees', context),
                _buildNavItem(Icons.bar_chart_rounded, 'Reports', '/admin/fees/reports', context),
                _buildNavItem(Icons.campaign_rounded, 'Announcements', '/admin/announcements', context),
                _buildNavItem(Icons.analytics_rounded, 'Risk Tracker', '/admin/risk-tracker', context),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Divider(color: Colors.white10),
                ),
                _buildNavItem(Icons.settings_rounded, 'Settings', '/admin/settings', context),
                _buildNavItem(Icons.logout_rounded, 'Logout', '/login', context, isLogout: true),
              ],
            ),
          ),
          
          // Collapse Toggle
          if (!isDrawer)
            InkWell(
              onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Icon(
                  _isSidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: Colors.white54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String route, BuildContext context, {bool isLogout = false}) {
    final location = GoRouterState.of(context).uri.toString();
    final isActive = location == route;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (isLogout) {
              ApiService.clearAuthToken();
              await AuthStore.instance.clear();
              if (context.mounted) context.go(route);
            } else {
              context.push(route);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.adminAccent : (isLogout ? Colors.redAccent : Colors.white70),
                  size: 22,
                ),
                if (!_isSidebarCollapsed || MediaQuery.of(context).size.width < 1100) ...[
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : (isLogout ? Colors.redAccent : Colors.white70),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
