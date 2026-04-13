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

  final List<String> _divisions = ['TE IT A', 'TE IT B', 'BE IT A', 'BE IT B', 'All Classes'];
  final List<Map<String, dynamic>> _severities = [
    {'label': 'Normal', 'color': Colors.blue, 'icon': Icons.info_outline},
    {'label': 'Important', 'color': Colors.orange, 'icon': Icons.priority_high_rounded},
    {'label': 'Urgent', 'color': Colors.red, 'icon': Icons.campaign_rounded},
  ];

  final List<Map<String, dynamic>> _history = [
    {
      'title': 'Unit Test Postponed',
      'message': 'The unit test scheduled for tomorrow is postponed to Monday.',
      'division': 'TE IT A',
      'severity': 'Important',
      'date': '2 hours ago'
    },
    {
      'title': 'New Study Material',
      'message': 'I have uploaded the notes for Chapter 4 in the assignments section.',
      'division': 'TE IT B',
      'severity': 'Normal',
      'date': 'Yesterday'
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
            
            // Division & Severity Row
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Target Division',
                    value: _selectedDivision,
                    items: _divisions,
                    onChanged: (val) => setState(() => _selectedDivision = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSeverityDropdown(),
                ),
              ],
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
          'message': _messageController.text,
          'division': _selectedDivision,
          'severity': _selectedSeverity,
          'attachment': _attachedFileName,
          'date': 'Just now'
        });
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

  Widget _buildAnnouncementHistory() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final ann = _history[index];
        final severity = _severities.firstWhere((s) => s['label'] == ann['severity']);
        final Color color = severity['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(ann['severity'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  Text(ann['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(ann['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ann['message'], style: const TextStyle(color: Colors.black87, height: 1.4)),
              
              if (ann['attachment'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_rounded, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(ann['attachment'], style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ann['division'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
