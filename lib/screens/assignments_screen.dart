import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_store.dart';
import 'ai_auto_grader_modal.dart';

class AssignmentsScreen extends StatefulWidget {
  final String classId;

  const AssignmentsScreen({super.key, required this.classId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _assignmentsFuture;
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  void _fetchAssignments() {
    _assignmentsFuture = _apiService.fetchAssignments(widget.classId);
  }

  void _showAiGraderModal(Map<String, dynamic> assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiAutoGraderModal(assignment: assignment),
    );
  }

  void _showCreateModal() {
    File? selectedFile;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: source, imageQuality: 85);
              if (picked != null) {
                setModalState(() => selectedFile = File(picked.path));
              }
            }

            Future<void> submitAssignment() async {
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();
              final date = _dateController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required'), backgroundColor: Colors.red),
                );
                return;
              }
              if (date.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deadline is required'), backgroundColor: Colors.red),
                );
                return;
              }
              // Must have attachment OR description
              if (selectedFile == null && desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You must either write questions/instructions or attach a photo.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }

              try {
                final teacherId = AuthStore.instance.currentUser?['id'] ?? '';
                final baseUrl = ApiService.baseUrl;
                final uri = Uri.parse('$baseUrl/assignments');
                final request = http.MultipartRequest('POST', uri);
                request.fields['classId'] = widget.classId;
                request.fields['teacherId'] = teacherId;
                request.fields['title'] = title;
                request.fields['description'] = desc;
                request.fields['deadline'] = date;

                if (selectedFile != null) {
                  final ext = selectedFile!.path.split('.').last.toLowerCase();
                  final mimeSubtype = (ext == 'pdf') ? 'pdf' : ext;
                  request.files.add(await http.MultipartFile.fromPath(
                    'media', selectedFile!.path,
                    contentType: http.MediaType('application', mimeSubtype),
                  ));
                }

                final streamed = await request.send();
                if (streamed.statusCode == 201) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Assignment created!'), backgroundColor: Colors.green),
                  );
                  _titleController.clear();
                  _descController.clear();
                  _dateController.clear();
                  Navigator.pop(context);
                  setState(() => _fetchAssignments());
                } else {
                  throw Exception('Server error: ${streamed.statusCode}');
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Questions / Instructions',
                        hintText: 'Write the assignment questions here...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // ── ATTACHMENT SECTION ─────────────────────────
                    const Text('📎 Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),

                    if (selectedFile != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6, right: 6,
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('✅ File attached. Tap ✕ to remove.', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 6),
                    const Text(
                      'Attach a photo of the assignment, or type questions above.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitAssignment,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Publish Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Assignments', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreateModal,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/quiz-creator'),
                    icon: const Icon(Icons.quiz_rounded, size: 18),
                    label: const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/quiz-results'),
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: const Text('Quiz Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _assignmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final assignments = snapshot.data ?? [];

                if (assignments.isEmpty) {
                  return const Center(child: Text('No assignments yet.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    assignment['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text('Due: ${assignment['deadline']}', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(assignment['description'], style: const TextStyle(color: Colors.black87)),
                            // Show media thumbnail if present
                            if (assignment['media_url'] != null && assignment['media_url'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  '${ApiService.baseUrl}/${assignment['media_url']}',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(child: Text('📎 Attachment', style: TextStyle(color: Colors.grey))),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => _showAiGraderModal(assignment),
                                icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                                label: const Text('Evaluate Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
