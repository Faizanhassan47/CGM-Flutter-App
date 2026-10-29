import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';

class DietAssistantScreen extends StatefulWidget {
  const DietAssistantScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<DietAssistantScreen> createState() => _DietAssistantScreenState();
}

class _DietAssistantScreenState extends State<DietAssistantScreen> {
  final _input = TextEditingController();
  String? _answer;
  bool _loading = false;
  @override
  void dispose() { _input.dispose(); super.dispose(); }
  Future<void> _ask() async {
    final message = _input.text.trim();
    if (message.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final answer = await widget.api.askDietAssistant(message);
      if (mounted) setState(() => _answer = answer);
    }
    catch (_) { if (mounted) setState(() => _answer = 'The assistant is unavailable right now. Please try again later.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(title: const Text('CGM Diet Assistant')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Ask about your glucose trends, meals, hydration, or food planning.', style: TextStyle(fontSize: 16, color: AppTheme.darkPurple)),
      const SizedBox(height: 8),
      const Text('General education only—not a diagnosis or medication advice.', style: TextStyle(color: AppTheme.textMuted)),
      const SizedBox(height: 20),
      TextField(controller: _input, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(hintText: 'Example: What meal patterns may help with my recent readings?')),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: _loading ? null : _ask, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: const Text('Ask assistant')),
      if (_answer != null) ...[const SizedBox(height: 24), Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_answer!, style: const TextStyle(fontSize: 15, height: 1.45))))],
    ]),
  );
}
