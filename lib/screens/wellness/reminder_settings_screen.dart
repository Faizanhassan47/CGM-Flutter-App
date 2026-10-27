import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'meal_reminders_screen.dart';
import 'water_reminders_screen.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  Map<String, dynamic> settings = {
    'mealEnabled': true,
    'waterEnabled': true,
    'waterIntervalMinutes': 120,
    'dailyWaterGoalMl': 2000,
    'quietHoursEnabled': true,
    'quietStart': '22:00',
    'quietEnd': '07:00',
    'timeZoneId': 'UTC',
  };
  List<dynamic> schedules = [];
  bool loading = true, saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.api.getWellnessReminders();
      if (mounted)
        setState(() {
          settings = {
            ...settings,
            ...((r['settings'] as Map?)?.cast<String, dynamic>() ?? {}),
          };
          schedules = (r['schedules'] as List?) ?? [];
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final r = await widget.api.updateWellnessReminders(settings);
      await NotificationService.instance.scheduleWellness(
        settings: (r['settings'] as Map?)?.cast<String, dynamic>() ?? settings,
        schedules: (r['schedules'] as List?) ?? schedules,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.restaurant_outlined)),
            title: const Text(
              'Meal Reminders',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Breakfast, lunch, dinner and custom meals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealRemindersScreen(api: widget.api),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.water_drop_outlined)),
            title: const Text(
              'Water Reminders',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Interval, daily goal and quiet hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WaterRemindersScreen(api: widget.api),
              ),
            ),
          ),
          const Divider(height: 28),
          SwitchListTile(
            title: const Text('Meal reminders'),
            value: settings['mealEnabled'] == true,
            onChanged: (v) => setState(() => settings['mealEnabled'] = v),
          ),
          SwitchListTile(
            title: const Text('Water reminders'),
            value: settings['waterEnabled'] == true,
            onChanged: (v) => setState(() => settings['waterEnabled'] = v),
          ),
          DropdownButtonFormField<int>(
            value: int.tryParse('${settings['waterIntervalMinutes']}') ?? 120,
            decoration: const InputDecoration(labelText: 'Water interval'),
            items: [30, 60, 90, 120, 180]
                .map(
                  (x) => DropdownMenuItem(value: x, child: Text('$x minutes')),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => settings['waterIntervalMinutes'] = v),
          ),
          TextFormField(
            initialValue: '${settings['dailyWaterGoalMl'] ?? ''}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily water goal (mL, optional)',
            ),
            onChanged: (v) => settings['dailyWaterGoalMl'] = int.tryParse(v),
          ),
          SwitchListTile(
            title: const Text('Quiet hours'),
            subtitle: Text(
              '${settings['quietStart']} – ${settings['quietEnd']}',
            ),
            value: settings['quietHoursEnabled'] == true,
            onChanged: (v) => setState(() => settings['quietHoursEnabled'] = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Meal schedules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...schedules.map(
            (s) => ListTile(
              dense: true,
              title: Text('${s['customName'] ?? s['mealType']}'),
              subtitle: Text(
                '${s['reminderTime']}  •  ${s['daysOfWeek'] ?? 'Every day'}',
              ),
              trailing: Switch(
                value: s['enabled'] != false,
                onChanged: (v) => setState(() => s['enabled'] = v),
              ),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add custom meal reminder'),
            onPressed: () async {
              final name = TextEditingController();
              final time = TextEditingController(text: '15:00');
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Custom meal'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: time,
                        decoration: const InputDecoration(
                          labelText: 'Time (HH:mm)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, name.text.trim().isNotEmpty),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                final row = await widget.api.createMealReminderSchedule({
                  'mealType': 'Custom',
                  'customName': name.text.trim(),
                  'reminderTime': time.text.trim(),
                  'daysOfWeek': '0,1,2,3,4,5,6',
                  'enabled': true,
                });
                setState(() => schedules.add(row));
              }
              name.dispose();
              time.dispose();
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Saving…' : 'Save reminders'),
          ),
        ],
      ),
    );
  }
}
