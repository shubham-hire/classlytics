import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';
import 'detailed_analytics_screen.dart';
import 'library_screen.dart';
import 'academic_planning_screen.dart';
import 'notice_board_screen.dart';
import 'certificates_screen.dart';
import 'feedback_screen.dart';
import 'quiz_list_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Segment (Compact Image Layout)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Top Blue Block
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5C6DF7), // Indigo/Blue matching the image
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Shubham Hire',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'STKBTCOE23536',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '2025-26',
                              style: TextStyle(
                                color: Color(0xFF5C6DF7),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom White Block (Department & Semester)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Department',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'B.E. (Computer)',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semester',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sixth Semester (Div A)',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Quick Stats
              Row(
                children: [
                  Expanded(child: _buildQuickStat('85%', 'Attendance', Icons.calendar_today_rounded, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickStat('72%', 'Avg Score', Icons.trending_up_rounded, Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickStat('2', 'Pending', Icons.pending_actions_rounded, Colors.orange)),
                ],
              ),
              const SizedBox(height: 32),

              // Financial Status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade50.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.account_balance_wallet_rounded, color: Colors.green.shade700, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFeeItem('Total Fee', '\$5,000', Colors.blue),
                        _buildFeeItem('Paid', '\$3,500', Colors.green),
                        _buildFeeItem('Pending', '\$1,500', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Campus Modules
              const Text(
                'Campus Modules',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildModuleButton(context, 'Academic Planning', Icons.calendar_month_rounded, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AcademicPlanningScreen()));
                  }),
                  _buildModuleButton(context, 'Library', Icons.local_library_rounded, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryScreen()));
                  }),
                  _buildModuleButton(context, 'Exams & Quizzes', Icons.quiz_rounded, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizListScreen()));
                  }),
                  _buildModuleButton(context, 'Notice Board', Icons.campaign_rounded, Colors.red, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeBoardScreen()));
                  }),
                  _buildModuleButton(context, 'Result Analysis', Icons.insights_rounded, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailedAnalyticsScreen()));
                  }),
                  _buildModuleButton(context, 'Certificates', Icons.card_membership_rounded, Colors.amber.shade600, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CertificatesScreen()));
                  }),
                  _buildModuleButton(context, 'Feedback', Icons.feedback_rounded, AppTheme.primaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 48),

              // Smart Insights
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade100.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.psychology_alt_rounded, color: Colors.orange.shade700, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Insight',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your math performance is dropping. Complete 2 pending assignments to recover.',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              const Text(
                'Upcoming Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              _buildUpcomingTaskCard('Physics Assignment', 'Tomorrow, 10:00 AM', 'Pending', Colors.red),
              const SizedBox(height: 16),
              _buildUpcomingTaskCard('Math Worksheet', '12 Apr, 11:59 PM', 'Urgent', Colors.orange),
              const SizedBox(height: 16),
              _buildUpcomingTaskCard('History Essay', '15 Apr, 08:00 AM', 'Pending', AppTheme.primaryColor),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUpcomingTaskCard(String title, String deadline, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    deadline,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    double width = (MediaQuery.of(context).size.width - 48 - 32) / 3; // 48 padding, 32 spacing
    if(width < 80) width = 90;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
