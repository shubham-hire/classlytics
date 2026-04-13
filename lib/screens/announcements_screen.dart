import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDivision = 'TE IT A';
  String _selectedSeverity = 'Normal';
  String? _attachedFileName;
  double? _attachedFileSize; // in KB
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _selectedClass = 'All Classes';
  String _selectedType = 'Announcement';
  bool _isSubmitting = false;

  final List<String> _divisions = ['TE IT A', 'TE IT B', 'BE IT A', 'BE IT B', 'All Classes'];
  final List<Map<String, dynamic>> _severities = [
    {'label': 'Normal', 'color': Colors.blue, 'icon': Icons.info_outline},
    {'label': 'Important', 'color': Colors.orange, 'icon': Icons.priority_high_rounded},
    {'label': 'Urgent', 'color': Colors.red, 'icon': Icons.campaign_rounded},
  ];

  final List<Map<String, dynamic>> _history = [
    {
      'title': 'School closed tomorrow',
      'body': 'Due to heavy rains, the school will remain closed tomorrow.',
      'class': 'All Classes',
      'date': 'Oct 24, 2026',
      'type': 'Notice',
    },
    {
      'title': 'Mid-term Exams Schedule',
      'body': 'The schedule for mid-term exams has been published. Please check the portal.',
      'class': 'Class 10 A',
      'date': 'Oct 22, 2026',
      'type': 'Announcement',
    },
    {
      'title': 'Annual Sports Meet 2026',
      'body': 'Registrations are now open for the Annual Sports Meet. Participate and win!',
      'class': 'All Classes',
      'date': 'Oct 20, 2026',
      'type': 'Event',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Class Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateAnnouncementCard(),
            const SizedBox(height: 32),
            _buildAIAlertsSection(),
            const SizedBox(height: 32),
            const Text('Previous Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            _buildAnnouncementHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAnnouncementCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Announcement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 20),
            
            const Text('Target Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'All Classes', child: Text('All Classes (Broadcast)')),
                DropdownMenuItem(value: 'Class 10 A', child: Text('Class 10 A')),
                DropdownMenuItem(value: 'Class 10 B', child: Text('Class 10 B')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedClass = val);
              },
            ),
            const SizedBox(height: 16),
            
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1E3A8A)),
              items: const [
                DropdownMenuItem(value: 'Announcement', child: Text('Announcement')),
                DropdownMenuItem(value: 'Notice', child: Text('Important Notice')),
                DropdownMenuItem(value: 'Event', child: Text('Event')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 20),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Title', Icons.title_rounded),
              validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            
            // Message Field
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: _inputDecoration('Message...', Icons.message_rounded),
              validator: (v) => v!.isEmpty ? 'Please enter a message' : null,
            ),
            const SizedBox(height: 20),

            // Attachment Section
            _buildAttachmentSection(),
            const SizedBox(height: 24),
            
            // Post Button
            ElevatedButton.icon(
              onPressed: _postAnnouncement,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Post Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Severity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSeverity,
              isExpanded: true,
              items: _severities.map((s) => DropdownMenuItem(
                value: s['label'] as String,
                child: Row(
                  children: [
                    Icon(s['icon'] as IconData, size: 16, color: s['color'] as Color),
                    const SizedBox(width: 8),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSeverity = val!),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  void _postAnnouncement() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _history.insert(0, {
          'title': _titleController.text,
          'body': _messageController.text,
          'class': _selectedClass,
          'type': _selectedType,
          'date': 'Just now',
        });
        _isSubmitting = false;
        _titleController.clear();
        _messageController.clear();
        _attachedFileName = null;
        _attachedFileSize = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Posted Successfully!'), backgroundColor: Colors.green));
    }
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachment (Max 400KB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _mockPickFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded, color: _attachedFileName != null ? Colors.blue : Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _attachedFileName ?? 'Click to attach PDF or Image',
                    style: TextStyle(
                      color: _attachedFileName != null ? Colors.black87 : Colors.grey,
                      fontSize: 13,
                      fontWeight: _attachedFileName != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_attachedFileName != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() { _attachedFileName = null; _attachedFileSize = null; }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mockPickFile() {
    // Simulated file picking logic
    setState(() {
      _attachedFileName = 'study_schedule_2025.pdf';
      _attachedFileSize = 385.0; // Mock 385 KB
    });
    
    if (_attachedFileSize! > 400.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large! Max 400KB allowed.'), backgroundColor: Colors.red));
      setState(() { _attachedFileName = null; _attachedFileSize = null; });
    }
  }

  Widget _buildAIAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Smart AI Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('AUTO', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAIAlertCard(
          "Anomaly Detected: Amit Verma",
          "Amit's attendance has dropped significantly by 18% over the last 2 weeks compared to the previous month.",
          "Attendance Anomaly",
          Icons.trending_down_rounded,
        ),
      ],
    );
  }

  Widget _buildAIAlertCard(String title, String message, String tag, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tag, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("View Profile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementHistory() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final type = item['type'] as String? ?? 'Announcement';
        
        Color typeColor = Colors.blue;
        IconData typeIcon = Icons.campaign_rounded;
        
        if (type == 'Notice') {
          typeColor = Colors.red;
          typeIcon = Icons.info_outline_rounded;
        } else if (type == 'Event') {
          typeColor = Colors.orange;
          typeIcon = Icons.event_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    item['date'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['body'] ?? '',
                style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.group_rounded, size: 14, color: Colors.blueGrey),
                   const SizedBox(width: 6),
                   Text(
                     'Sent to: ${item['class']}',
                     style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600),
                   ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
