import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WellnessHistoryScreen extends StatefulWidget {
  const WellnessHistoryScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<WellnessHistoryScreen> createState() => _WellnessHistoryScreenState();
}

class _WellnessHistoryScreenState extends State<WellnessHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  bool loading = true;
  List<dynamic> meals = [];
  List<dynamic> water = [];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(const Duration(days: 30));
    try {
      final results = await Future.wait<dynamic>([
        widget.api.getMeals(
          from: start.toIso8601String(),
          to: end.toIso8601String(),
        ),
        widget.api.getWater(
          from: start.toIso8601String(),
          to: end.toIso8601String(),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        meals = (results[0]['items'] as List?) ?? [];
        water = results[1] as List<dynamic>;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteMeal(dynamic item) async {
    await widget.api.deleteMeal((item['id'] as num).toInt());
    if (mounted) setState(() => meals.remove(item));
  }

  Future<void> _deleteWater(dynamic item) async {
    await widget.api.deleteWater((item['id'] as num).toInt());
    if (mounted) setState(() => water.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness History'),
        bottom: TabBar(
          controller: tabs,
          tabs: [
            Tab(text: 'Meals (${meals.length})'),
            Tab(text: 'Water (${water.length})'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: tabs,
                children: [_mealList(), _waterList()],
              ),
            ),
    );
  }

  Widget _mealList() {
    if (meals.isEmpty)
      return _empty(
        Icons.restaurant_outlined,
        'No meals logged in the last 30 days.',
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (_, index) {
        final item = meals[index];
        final carbs = item['carbohydratesGrams'];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFE8E8),
              foregroundColor: Color(0xFFFF3B3B),
              child: Icon(Icons.restaurant),
            ),
            title: Text(
              '${item['mealType'] ?? 'Meal'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${item['foodDescription'] ?? ''}\n${_date(item['occurredAtUtc'])}${carbs == null ? '' : '  •  $carbs g carbs'}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _confirmDelete(() => _deleteMeal(item));
                if (value == 'glucose') _showGlucose(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'glucose',
                  child: Text('View glucose around meal'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _waterList() {
    if (water.isEmpty)
      return _empty(
        Icons.water_drop_outlined,
        'No water logged in the last 30 days.',
      );
    final total = water.fold<int>(
      0,
      (sum, item) => sum + ((item['amountMl'] as num?)?.toInt() ?? 0),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop, color: Color(0xFF168DE2)),
            title: const Text(
              '30-day total',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: Text(
              '$total mL',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF168DE2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...water.map(
          (item) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF6FF),
                foregroundColor: Color(0xFF168DE2),
                child: Icon(Icons.water_drop_outlined),
              ),
              title: Text(
                '${item['amountMl'] ?? 0} mL',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(_date(item['occurredAtUtc'])),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(() => _deleteWater(item)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(IconData icon, String text) => ListView(
    children: [
      const SizedBox(height: 110),
      Icon(icon, size: 48, color: Colors.black26),
      const SizedBox(height: 12),
      Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    ],
  );
  String _date(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal().toString().substring(0, 16) ??
      '$value';

  Future<void> _confirmDelete(Future<void> Function() action) async {
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete entry?'),
            content: const Text(
              'This entry will be removed from your wellness history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (yes) await action();
  }

  Future<void> _showGlucose(dynamic item) async {
    final result = await widget.api.getMealGlucose((item['id'] as num).toInt());
    if (!mounted) return;
    final analysis = result['analysis'] as Map?;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Glucose around meal'),
        content: Text(
          analysis == null
              ? '${result['message'] ?? 'No analysis available.'}'
              : 'Baseline: ${analysis['baseline']}\nPeak: ${analysis['peak']}\nChange: ${analysis['delta']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
