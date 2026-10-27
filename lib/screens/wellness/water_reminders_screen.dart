import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'wellness_history_screen.dart';

class WaterRemindersScreen extends StatefulWidget {
  const WaterRemindersScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<WaterRemindersScreen> createState() => _WaterRemindersScreenState();
}

class _WaterRemindersScreenState extends State<WaterRemindersScreen> {
  static const blue = Color(0xFF168DE2);
  static const ink = Color(0xFF10203A);
  Map<String, dynamic> settings = {};
  bool loading = true;
  bool saving = false;
  late final TextEditingController goalController;

  @override
  void initState() {
    super.initState();
    goalController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    goalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await widget.api.getWellnessReminders();
      if (!mounted) return;
      final loaded =
          (response['settings'] as Map?)?.cast<String, dynamic>() ?? {};
      goalController.text = '${loaded['dailyWaterGoalMl'] ?? ''}';
      setState(() {
        settings = loaded;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final interval =
          int.tryParse('${settings['waterIntervalMinutes'] ?? 120}') ?? 120;
      if (interval < 5 || interval > 720) {
        throw const FormatException(
          'Interval must be between 5 and 720 minutes.',
        );
      }
      final goal = int.tryParse(goalController.text.trim());
      if (goal != null && (goal < 0 || goal > 20000)) {
        throw const FormatException(
          'Daily goal must be between 0 and 20,000 mL.',
        );
      }
      final payload = <String, dynamic>{
        'waterEnabled': settings['waterEnabled'] != false,
        'waterIntervalMinutes': interval,
        'dailyWaterGoalMl': goal,
        'quietHoursEnabled': settings['quietHoursEnabled'] != false,
        'quietStart': settings['quietStart'] ?? '22:00',
        'quietEnd': settings['quietEnd'] ?? '07:00',
      };
      final response = await widget.api.updateWellnessReminders(payload);
      await NotificationService.instance.scheduleWellness(
        settings:
            (response['settings'] as Map?)?.cast<String, dynamic>() ?? payload,
        schedules: (response['schedules'] as List?) ?? [],
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Water reminders saved')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not save water reminders. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _customInterval() async {
    final controller = TextEditingController(
      text: '${settings['waterIntervalMinutes'] ?? 120}',
    );
    String? error;
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Custom reminder interval'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes',
              hintText: '5–720 minutes',
              suffixText: 'min',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 5 || parsed > 720) {
                  setDialogState(
                    () => error = 'Enter a whole number from 5 to 720.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, parsed);
              },
              child: const Text('Use interval'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      setState(() => settings['waterIntervalMinutes'] = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final interval =
        int.tryParse('${settings['waterIntervalMinutes'] ?? 120}') ?? 120;
    final goal = int.tryParse(goalController.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Water Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _hero(goal),
          const SizedBox(height: 16),
          _toggleCard(),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WellnessHistoryScreen(api: widget.api),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('View water history'),
          ),
          const SizedBox(height: 26),
          const Text(
            'Reminder interval',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 60, 90, 120, 180]
                .map(
                  (value) => ChoiceChip(
                    label: Text('$value min'),
                    selected: interval == value,
                    selectedColor: const Color(0xFFDDF0FF),
                    labelStyle: TextStyle(
                      color: interval == value ? blue : ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(
                      () => settings['waterIntervalMinutes'] = value,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: Text(
              [30, 60, 90, 120, 180].contains(interval)
                  ? 'Set custom interval'
                  : 'Custom: $interval minutes',
            ),
            onPressed: _customInterval,
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily hydration goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.water_drop_outlined, color: blue),
              suffixText: 'mL',
              hintText: 'For example, 2000',
              labelText: 'Goal amount',
            ),
          ),
          const SizedBox(height: 18),
          _quietCard(),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: blue),
              title: Text(
                'Make it easy',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Keep a bottle nearby and log water as you drink it. This target is a wellness preference, not medical advice.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(saving ? 'Saving...' : 'Save water settings'),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(int goal) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6FF),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          foregroundColor: blue,
          child: Icon(Icons.water_drop_outlined),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stay hydrated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                goal > 0
                    ? 'Your daily goal is ${goal} mL.'
                    : 'Set a daily goal and choose when we should remind you.',
                style: const TextStyle(color: Colors.black54, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _toggleCard() => Card(
    child: SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      secondary: const CircleAvatar(
        backgroundColor: Color(0xFFDDF0FF),
        foregroundColor: blue,
        child: Icon(Icons.notifications_active_outlined),
      ),
      title: const Text(
        'Water reminders',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        settings['waterEnabled'] != false
            ? 'Reminders are active'
            : 'Reminders are paused',
      ),
      value: settings['waterEnabled'] != false,
      activeColor: blue,
      onChanged: (value) => setState(() => settings['waterEnabled'] = value),
    ),
  );

  Widget _quietCard() => Card(
    child: Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
          secondary: const CircleAvatar(
            backgroundColor: Color(0xFFEAF6FF),
            foregroundColor: blue,
            child: Icon(Icons.nightlight_outlined),
          ),
          title: const Text(
            'Quiet hours',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Pause reminders while you sleep'),
          value: settings['quietHoursEnabled'] != false,
          activeColor: blue,
          onChanged: (value) =>
              setState(() => settings['quietHoursEnabled'] = value),
        ),
        const Divider(height: 1, indent: 72),
        ListTile(
          contentPadding: const EdgeInsets.only(left: 72, right: 18),
          title: const Text('Schedule'),
          trailing: Text(
            '${settings['quietStart'] ?? '22:00'} – ${settings['quietEnd'] ?? '07:00'}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
        ),
      ],
    ),
  );
}
