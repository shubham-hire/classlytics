import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classlytics/core/theme/app_theme.dart';
import 'package:classlytics/features/dashboard/presentation/dashboard_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscureText = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final user = result['user'];
      final role = (user['role'] as String).toLowerCase();

      AuthStore.instance.setUser(user);

      if (mounted) {
        if (role == 'teacher') {
          context.go('/teacher-dashboard');
        } else if (role == 'student') {
          context.go('/dashboard', extra: UserRole.student);
        } else if (role == 'parent') {
          context.go('/dashboard', extra: UserRole.parent);
        } else if (role == 'admin') {
          context.go('/admin');
        } else {
          context.go('/teacher-dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString().replaceAll('Exception: Network error: Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( // ✅ ONLY ONE SCROLL (FIXED)
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // Logo
                    Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Welcome to Classlytics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(hintText: 'Email Address'),
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign In
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign In'),
                    ),

                    const SizedBox(height: 24),

                    // Admin Dashboard Demo
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      label: const Text('Admin Dashboard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Teacher Demo
                    OutlinedButton(
                      onPressed: () => context.go('/teacher-dashboard'),
                      child: const Text('Teacher Dashboard Demo'),
                    ),

                    const SizedBox(height: 12),

                    // Parent Demo
                    OutlinedButton(
                      onPressed: () => context.go('/dashboard', extra: UserRole.parent),
                      child: const Text('Parent Dashboard Demo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}