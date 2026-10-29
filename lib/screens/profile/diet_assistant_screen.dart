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
  String? _question;
  String? _answer;
  bool _loading = false;

  static const _quickQuestions = [
    (
      'Meal suggestions',
      'What should I eat for breakfast?',
      Icons.restaurant_outlined,
    ),
    (
      'Analyze my report',
      'Explain my recent glucose patterns.',
      Icons.bar_chart_rounded,
    ),
    (
      'Healthy alternatives',
      'Suggest healthier food alternatives.',
      Icons.eco_outlined,
    ),
    (
      'Hydration guidance',
      'How can I improve my hydration?',
      Icons.water_drop_outlined,
    ),
    (
      'Pakistani meals',
      'Suggest a healthy Pakistani lunch.',
      Icons.ramen_dining_outlined,
    ),
    (
      'Nutrition tips',
      'How can I add more fiber and protein?',
      Icons.lightbulb_outline_rounded,
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _ask([String? suggestedQuestion]) async {
    final message = (suggestedQuestion ?? _input.text).trim();
    if (message.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _question = message;
      _answer = null;
      _loading = true;
    });
    try {
      final answer = await widget.api.askDietAssistant(message);
      if (mounted) setState(() => _answer = answer);
    } catch (_) {
      if (mounted) {
        setState(
          () => _answer =
              'The assistant is unavailable right now. Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFAFD),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppTheme.darkPurple),
        title: const Text(
          'AI Diet Assistant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppTheme.darkPurple,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          _buildStatusBar(),
          const SizedBox(height: 14),
          _buildCgmDataCard(),
          if (_question == null) ...[
            const SizedBox(height: 22),
            const Text(
              'Quick Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickQuestions(),
            const SizedBox(height: 22),
            _buildRecentQuestions(),
          ] else ...[
            const SizedBox(height: 18),
            _buildConversation(),
          ],
          const SizedBox(height: 18),
          _buildComposer(),
          const SizedBox(height: 10),
          const Text(
            'General education only. Do not change medication or insulin without your clinician.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF18B979),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 7),
      const Text(
        'Online',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkPurple,
        ),
      ),
      const Text(
        ' • Health & Nutrition Focused',
        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
    ],
  );

  Widget _buildCgmDataCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F3),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: Color(0xFFFF3D48),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Using your CGM data',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Recent readings, meals and hydration',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Change',
            style: TextStyle(
              color: Color(0xFFFF3D48),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildQuickQuestions() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _quickQuestions.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.25,
    ),
    itemBuilder: (_, index) {
      final item = _quickQuestions[index];
      return InkWell(
        onTap: () => _ask(item.$2),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE8F1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$3, color: const Color(0xFFFF7043), size: 25),
              const Spacer(),
              Text(
                item.$1,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Ask AIMA',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildRecentQuestions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Recent Questions',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.darkPurple,
        ),
      ),
      const SizedBox(height: 8),
      ...[
        'What caused my glucose spike yesterday?',
        'Suggest a healthy lunch',
        'Explain my time in range',
      ].map(
        (question) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            question,
            style: const TextStyle(fontSize: 13, color: AppTheme.darkPurple),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
          ),
          onTap: () => _ask(question),
        ),
      ),
    ],
  );

  Widget _buildConversation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3D48),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _question!,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE8F1)),
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            : Text(
                _answer ?? '',
                style: const TextStyle(
                  height: 1.45,
                  color: AppTheme.darkPurple,
                ),
              ),
      ),
    ],
  );

  Widget _buildComposer() => Container(
    padding: const EdgeInsets.only(left: 14, right: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFEDE8F1)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _input,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _ask(),
            decoration: const InputDecoration(
              hintText: 'Ask a nutrition question...',
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        IconButton(
          onPressed: _loading ? null : _ask,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFF3D48),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.send_rounded, size: 19),
        ),
      ],
    ),
  );
}
