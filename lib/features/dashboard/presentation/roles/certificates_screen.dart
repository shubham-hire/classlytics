import 'package:flutter/material.dart';
import 'package:classlytics/core/theme/app_theme.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Certificates', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
        children: [
          _buildCertificateCard('Hackathon Winner', 'TechFest 2025', Icons.emoji_events_rounded, Colors.amber.shade600),
          _buildCertificateCard('Python Certification', 'Coursera', Icons.code_rounded, Colors.blue),
          _buildCertificateCard('Sports Captain', 'Annual Sports', Icons.sports_kabaddi_rounded, Colors.orange),
          _buildCertificateCard('Perfect Attendance', 'Semester 5', Icons.star_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(String title, String issuer, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 4),
          Text(issuer, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
