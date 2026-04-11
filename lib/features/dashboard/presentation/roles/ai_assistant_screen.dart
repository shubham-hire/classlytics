import 'package:flutter/material.dart';
import 'package:main_app/core/theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  int _selectedTab = 0; // 0 = Homework Help, 1 = Study Planner

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Classlytics AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Mode Toggle
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTab == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Homework Help',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTab == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Study Planner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1 ? Colors.orange.shade700 : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Chat Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _selectedTab == 0 ? _buildHomeworkChat() : _buildPlannerChat(),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.textSecondary),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: _selectedTab == 0 ? 'Type a question or upload a photo...' : 'Ask for a study schedule...',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHomeworkChat() {
    return [
      _buildUserMessage('Can you help me solve this quadratic equation: x² - 5x + 6 = 0?'),
      const SizedBox(height: 16),
      _buildAIMessage('Of course! Let\'s break it down step-by-step:\n\n1. We need to find two numbers that multiply to 6 and add up to -5.\n2. Those numbers are -2 and -3.\n3. So, we can factor the equation as: (x - 2)(x - 3) = 0\n4. Therefore, the solutions are x = 2 and x = 3.'),
    ];
  }

  List<Widget> _buildPlannerChat() {
    return [
      _buildAIMessage('Hi Shubham! I noticed you have a Physics exam in 3 days and your previous scores show you struggle with Kinematics. Would you like me to generate a 3-day study plan focusing on that?', isPlanner: true),
      const SizedBox(height: 16),
      _buildUserMessage('Yes, please do.'),
      const SizedBox(height: 16),
      _buildAIMessage('**Your 3-Day Kinematics Plan**\n\n📌 **Day 1 (Today):** Review equations of motion. Watch the video lecture attached.\n📌 **Day 2:** Solve 15 practice problems. I will generate a mini-quiz for you.\n📌 **Day 3:** Full mock test. Review mistakes.\n\nShall I add these to your task list?', isPlanner: true),
    ];
  }

  Widget _buildUserMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 40),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4), // Pointy part
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildAIMessage(String text, {bool isPlanner = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPlanner ? Colors.orange.shade50 : Colors.white,
          border: Border.all(color: isPlanner ? Colors.orange.shade200 : Colors.grey.shade200),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4), // Pointy part
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Text(text, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.5)),
      ),
    );
  }
}
