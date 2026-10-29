import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'wellness_history_screen.dart';

class MealRemindersScreen extends StatefulWidget {
  const MealRemindersScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<MealRemindersScreen> createState() => _MealRemindersScreenState();
}

class _MealRemindersScreenState extends State<MealRemindersScreen> {
  static const coral = Color(0xFFFF3B3B);
  static const ink = Color(0xFF10203A);
  List<dynamic> schedules = [];
  bool enabled = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await widget.api.getWellnessReminders();
      if (!mounted) return;
      setState(() {
        schedules = (response['schedules'] as List?) ?? [];
        enabled = (response['settings'] as Map?)?['mealEnabled'] != false;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _reschedule() async {
    try {
      final response = await widget.api.getWellnessReminders();
      final settings = (response['settings'] as Map?)?.cast<String, dynamic>() ?? {};
      final scheds = (response['schedules'] as List?) ?? schedules;
      await NotificationService.instance.scheduleWellness(
        settings: settings,
        schedules: scheds,
      );
    } catch (_) {}
  }

  Future<void> _saveEnabled(bool value) async {
    setState(() => enabled = value);
    await widget.api.updateWellnessReminders({'mealEnabled': value});
    await _reschedule();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final time = TextEditingController(text: '15:00');
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add custom meal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a name and time for your reminder.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Meal name',
                prefixIcon: Icon(Icons.restaurant_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: time,
              decoration: const InputDecoration(
                labelText: 'Time (HH:mm)',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (name.text.trim().isNotEmpty)
                    Navigator.pop(sheetContext, {
                      'name': name.text.trim(),
                      'time': time.text.trim(),
                    });
                },
                child: const Text('Add reminder'),
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    time.dispose();
    if (result == null) return;
    final row = await widget.api.createMealReminderSchedule({
      'mealType': 'Custom',
      'customName': result['name'],
      'reminderTime': result['time'],
      'daysOfWeek': '0,1,2,3,4,5,6',
      'enabled': true,
    });
    if (mounted) setState(() => schedules.add(row));
    await _reschedule();
  }

  String _displayTime(dynamic value) {
    final raw = '$value';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    return '${hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)}:$minute ${hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Reminders')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _hero(),
            const SizedBox(height: 16),
            _switchCard(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WellnessHistoryScreen(api: widget.api),
                ),
              ),
              icon: const Icon(Icons.history),
              label: const Text('View meal history'),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                Text(
                  '${schedules.length} reminders',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (schedules.isEmpty)
              _empty()
            else
              ...schedules.map(_scheduleCard),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add custom meal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: coral,
                side: const BorderSide(color: coral),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 14),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: coral),
                title: Text(
                  'Small, consistent routines help',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Reminders are wellness prompts. Adjust them to your personal routine.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          foregroundColor: coral,
          child: Icon(Icons.restaurant_menu),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your meals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Stay on track with gentle reminders throughout your day.',
                style: TextStyle(color: Colors.black54, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _switchCard() => Card(
    child: SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      secondary: const CircleAvatar(
        backgroundColor: Color(0xFFFFE4E4),
        foregroundColor: coral,
        child: Icon(Icons.notifications_active_outlined),
      ),
      title: const Text(
        'Meal reminders',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(enabled ? 'Reminders are active' : 'Reminders are paused'),
      value: enabled,
      activeColor: coral,
      onChanged: _saveEnabled,
    ),
  );

  Widget _scheduleCard(dynamic schedule) {
    final type = '${schedule['customName'] ?? schedule['mealType'] ?? 'Meal'}';
    return Card(
      child: ListTile(
        onTap: () => _editTime(schedule),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF1F1),
          foregroundColor: coral,
          child: Icon(
            type.toLowerCase().contains('snack')
                ? Icons.apple
                : Icons.restaurant,
          ),
        ),
        title: Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
        ),
        subtitle: Text(
          '${_displayTime(schedule['reminderTime'])}  •  Every day',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 18, color: Colors.black38),
            const SizedBox(width: 8),
            Icon(
              enabled && schedule['enabled'] != false
                  ? Icons.check_circle
                  : Icons.pause_circle_outline,
              color: enabled && schedule['enabled'] != false
                  ? Colors.green
                  : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTime(dynamic schedule) async {
    final raw = '${schedule['reminderTime'] ?? '08:00'}';
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText:
          'Set ${schedule['customName'] ?? schedule['mealType']} reminder time',
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final id = (schedule['id'] as num?)?.toInt();
    if (id == null) return;
    final updated = await widget.api.updateMealReminderSchedule(id, {
      'reminderTime': time,
    });
    if (!mounted) return;
    setState(() {
      final index = schedules.indexOf(schedule);
      if (index >= 0) schedules[index] = updated;
    });
    await _reschedule();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${schedule['customName'] ?? schedule['mealType']} time updated',
        ),
      ),
    );
  }

  Widget _empty() => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 42, color: coral),
          SizedBox(height: 10),
          Text(
            'No meal reminders yet',
            style: TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          SizedBox(height: 4),
          Text(
            'Add your first reminder to build a routine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}
