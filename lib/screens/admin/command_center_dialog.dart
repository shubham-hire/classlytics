import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class CommandCenterDialog extends StatefulWidget {
  const CommandCenterDialog({super.key});

  @override
  State<CommandCenterDialog> createState() => _CommandCenterDialogState();
}

class _CommandCenterDialogState extends State<CommandCenterDialog> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _response;

  void _submit() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final answer = await _api.askAdminCommandCenter(query);
      if (mounted) {
        setState(() {
          _response = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _response = "I'm having trouble connecting to the network right now. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.adminAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: 'Ask the Admin AI anything...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.adminPrimary),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.adminPrimary),
                      onPressed: _submit,
                    ),
                ],
              ),
            ),
            
            // Response Area
            if (_response != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _response!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              )
            else if (!_isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.tips_and_updates_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Try asking:\n"How many students are enrolled?"\n"What is our total expected revenue?"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
