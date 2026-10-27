import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/wellness_offline_store.dart';
import 'reminder_settings_screen.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  static const coral = Color(0xFFFF3B3B);
  static const ink = Color(0xFF10203A);
  static const paleRed = Color(0xFFFFF1F1);
  static const paleBlue = Color(0xFFEFF9FF);
  bool loading = true;
  String? error;
  Map<String, dynamic> today = {};
  Map<String, dynamic> reminders = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _syncPending();
    try {
      final now = DateTime.now().toUtc();
      final start = DateTime(now.year, now.month, now.day).toUtc();
      final result = await Future.wait([
        widget.api.getWellnessToday(
          startUtc: start.toIso8601String(),
          endUtc: now.toIso8601String(),
        ),
        widget.api.getWellnessReminders(),
      ]);
      if (mounted)
        setState(() {
          today = result[0];
          reminders = result[1];
          loading = false;
          error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = '$e';
          loading = false;
        });
    }
  }

  Future<void> _syncPending() async {
    final pending = await WellnessOfflineStore.pending();
    final remaining = <Map<String, dynamic>>[];
    for (final event in pending) {
      try {
        if (event['kind'] == 'water')
          await widget.api.createWater(event['data']);
        if (event['kind'] == 'meal') await widget.api.createMeal(event['data']);
      } catch (_) {
        remaining.add(event);
      }
    }
    if (remaining.length != pending.length)
      await WellnessOfflineStore.replace(remaining);
  }

  Future<void> _water(int amount) async {
    final event = {
      'amountMl': amount,
      'occurredAtUtc': DateTime.now().toUtc().toIso8601String(),
      'clientEventId': 'water-${DateTime.now().microsecondsSinceEpoch}',
    };
    try {
      await widget.api.createWater(event);
    } catch (_) {
      await WellnessOfflineStore.add({'kind': 'water', 'data': event});
      _snack('Saved offline; it will sync when connected.');
    }
    await _load();
  }

  Future<void> _meal() async {
    final food = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.of(sheetContext).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Log Meal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Meal type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                  .map(
                    (x) => ChoiceChip(
                      label: Text(x),
                      selected: x == 'Breakfast',
                      selectedColor: paleRed,
                      onSelected: (_) {},
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: food,
              maxLength: 4000,
              decoration: const InputDecoration(
                labelText: 'Food / meal description',
                prefixIcon: Icon(Icons.restaurant_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: coral,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => Navigator.pop(sheetContext, food.text.trim()),
                child: const Text('Save Meal'),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final event = {
        'mealType': 'Breakfast',
        'foodDescription': result.trim(),
        'occurredAtUtc': DateTime.now().toUtc().toIso8601String(),
        'clientEventId': 'meal-${DateTime.now().microsecondsSinceEpoch}',
      };
      try {
        await widget.api.createMeal(event);
      } catch (_) {
        await WellnessOfflineStore.add({'kind': 'meal', 'data': event});
        _snack('Saved offline; it will sync when connected.');
      }
      await _load();
    }
    food.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null)
      return Scaffold(
        appBar: AppBar(title: const Text('Wellness')),
        body: Center(child: Text(error!)),
      );
    final meals = (today['meals'] as List?)?.length ?? 0;
    final water = (today['waterMl'] as num?)?.toInt() ?? 0;
    final goal = ((reminders['settings'] as Map?)?['dailyWaterGoalMl'] as num?)
        ?.toInt();
    final ratio = goal == null || goal <= 0
        ? null
        : (water / goal).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        title: const Text(
          'Wellness',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReminderSettingsScreen(api: widget.api),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _periodTabs(),
            const SizedBox(height: 22),
            const Text(
              "Today's Progress",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _progressCard(
                    'Meals',
                    '$meals / 3',
                    Icons.restaurant,
                    paleRed,
                    (meals / 3).clamp(0.0, 1.0),
                    'Next: Dinner 7:30 PM',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _progressCard(
                    'Water',
                    '$water mL',
                    Icons.water_drop_outlined,
                    paleBlue,
                    ratio,
                    goal == null ? 'Goal disabled' : 'Goal: $goal mL',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _action('＋  Log Meal', _meal, coral)),
                const SizedBox(width: 10),
                Expanded(
                  child: _action(
                    '＋  Add Water',
                    () => _water(250),
                    const Color(0xFFFFEDED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Upcoming Reminders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            _reminderTile(
              Icons.restaurant,
              'Dinner',
              'Today at 7:30 PM',
              'In 4h 20m',
              paleRed,
            ),
            _reminderTile(
              Icons.water_drop_outlined,
              'Water reminder',
              'Today at 9:00 PM',
              'In 5h 50m',
              paleBlue,
            ),
            const SizedBox(height: 24),
            const Text(
              "Today's Timeline",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            ..._timeline(),
            const SizedBox(height: 18),
            const Text(
              'Wellness reminders are optional and separate from critical CGM alerts.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodTabs() {
    final tabs = ['Today', 'Week', 'Month']
        .map(
          (x) => Expanded(
            child: Container(
              decoration: x == 'Today'
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                x,
                style: TextStyle(
                  color: x == 'Today' ? coral : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        )
        .toList();
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: tabs),
    );
  }

  Widget _progressCard(
    String title,
    String value,
    IconData icon,
    Color bg,
    double? progress,
    String foot,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: title == 'Meals' ? coral : const Color(0xFF159BE8)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: ink, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white70,
          color: title == 'Meals' ? coral : const Color(0xFF159BE8),
        ),
        const SizedBox(height: 7),
        Text(foot, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    ),
  );
  Widget _action(String text, VoidCallback onTap, Color color) => SizedBox(
    height: 46,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == coral ? Colors.white : coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
  Widget _reminderTile(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color bg,
  ) => Card(
    elevation: 0,
    color: Colors.white,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: bg,
        child: Icon(icon, color: coral),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: const TextStyle(color: coral, fontWeight: FontWeight.w700),
      ),
    ),
  );
  List<Widget> _timeline() {
    final events = [
      ...((today['meals'] as List?) ?? []),
      ...((today['water'] as List?) ?? []),
    ];
    if (events.isEmpty)
      return [
        const Card(
          child: ListTile(
            leading: Icon(Icons.event_note_outlined),
            title: Text('No wellness events yet'),
            subtitle: Text('Log a meal or add water to start your timeline.'),
          ),
        ),
      ];
    events.sort(
      (a, b) => '${a['occurredAtUtc']}'.compareTo('${b['occurredAtUtc']}'),
    );
    return events.reversed.take(8).map((e) {
      final isWater = e['amountMl'] != null;
      final time = DateTime.tryParse('${e['occurredAtUtc']}');
      return Card(
        elevation: 0,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isWater ? paleBlue : paleRed,
            child: Icon(
              isWater ? Icons.water_drop_outlined : Icons.restaurant,
              color: coral,
            ),
          ),
          title: Text(
            isWater ? 'Water' : '${e['mealType'] ?? 'Meal'}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          subtitle: Text(
            isWater ? '${e['amountMl']} mL' : '${e['foodDescription'] ?? ''}',
          ),
          trailing: Text(
            time == null ? '' : DateFormat.jm().format(time.toLocal()),
          ),
        ),
      );
    }).toList();
  }
}
