import 'package:flutter/material.dart';

class DigitalLibraryManagementScreen extends StatefulWidget {
  const DigitalLibraryManagementScreen({super.key});

  @override
  State<DigitalLibraryManagementScreen> createState() => _DigitalLibraryManagementScreenState();
}

class _DigitalLibraryManagementScreenState extends State<DigitalLibraryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _eResources = [
    {
      'title': 'Operating Systems Lecture Notes',
      'class': 'TE IT A',
      'type': 'Link • Google Drive',
      'icon': Icons.link_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Data Structures Cheatsheet',
      'class': 'All Classes',
      'type': 'PDF File • 2.5 MB',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddResourceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload E-Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 20),
            TextField(
              decoration: _inputDecoration('Title', Icons.title_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'All Classes',
              decoration: _inputDecoration('Target Class', Icons.class_rounded),
              items: const [
                DropdownMenuItem(value: 'All Classes', child: Text('All Classes')),
                DropdownMenuItem(value: 'TE IT A', child: Text('TE IT A')),
              ],
              onChanged: (val) {},
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5), style: BorderStyle.none), // Should be dash in prod
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: Colors.blueAccent, size: 40),
                  SizedBox(height: 8),
                  Text('Tap to upload PDF, Notes or Paste Link', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Publish Resource', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Digital Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'E-Resources'),
            Tab(text: 'Library Records'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Resource'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // E-Resources Tab
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _eResources.length,
            itemBuilder: (context, index) {
              final r = _eResources[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: (r['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(r['icon'] as IconData, color: r['color'] as Color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(r['type'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(r['class'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    )
                  ],
                ),
              );
            },
          ),

          // Library Records Tab (books issued by library staff, view only for teacher)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Physical Book Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                const SizedBox(height: 8),
                const Text('Synced from central library database.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sync Records'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
