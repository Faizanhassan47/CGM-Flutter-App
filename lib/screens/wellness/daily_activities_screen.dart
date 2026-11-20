import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/wellness_offline_store.dart';
import '../../widgets/page_top_bar.dart';
import 'meal_reminders_screen.dart';
import 'water_reminders_screen.dart';

class DailyActivitiesScreen extends StatelessWidget {
  const DailyActivitiesScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: PageTopBar(
                  title: 'Activities',
                  subtitle: 'Meals, insulin, exercise, and water',
                  leading: Navigator.of(context).canPop()
                      ? PageTopAction(
                          icon: Icons.chevron_left,
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : null,
                ),
              ),
              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Log'),
                  Tab(text: 'Meals'),
                  Tab(text: 'Water'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ActivityLogTab(api: api),
                    MealRemindersScreen(api: api, embedded: true),
                    WaterRemindersScreen(api: api, embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLogTab extends StatefulWidget {
  const _ActivityLogTab({required this.api});
  final ApiService api;
  @override
  State<_ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<_ActivityLogTab>
    with WidgetsBindingObserver {
  DateTime day = DateTime.now();
  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  DateTime get _start => DateTime(day.year, day.month, day.day);
  DateTime get _end => _start.add(const Duration(days: 1));

  int? _waterAmount(Map<String, dynamic> row) {
    final direct = row['amountMl'] ?? row['AmountMl'];
    if (direct != null) return int.tryParse('$direct');
    final payload = (row['payload'] as Map?)?.cast<String, dynamic>();
    if (payload == null) return null;
    return int.tryParse('${payload['amountMl'] ?? payload['AmountMl'] ?? ''}');
  }

  Future<void> _syncPendingWater() async {
    final pending = await WellnessOfflineStore.pending();
    if (pending.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final event in pending) {
      try {
        if (event['kind'] == 'water') {
          await widget.api.createWater(
            Map<String, dynamic>.from(event['data'] as Map),
          );
        } else if (event['kind'] == 'meal') {
          await widget.api.createMeal(
            Map<String, dynamic>.from(event['data'] as Map),
          );
        } else {
          remaining.add(event);
        }
      } catch (_) {
        remaining.add(event);
      }
    }
    if (remaining.length != pending.length) {
      await WellnessOfflineStore.replace(remaining);
    }
  }

  List<Map<String, dynamic>> _pendingWaterForDay(
    List<Map<String, dynamic>> pending,
    Set<String> knownClientIds,
  ) {
    final fromUtc = _start.toUtc();
    final toUtc = _end.toUtc();
    final rows = <Map<String, dynamic>>[];
    for (final event in pending) {
      if (event['kind'] != 'water') continue;
      final data = Map<String, dynamic>.from(event['data'] as Map? ?? {});
      final clientId = '${data['clientEventId'] ?? ''}';
      if (clientId.isNotEmpty && knownClientIds.contains(clientId)) continue;
      final at = DateTime.tryParse('${data['occurredAtUtc']}');
      if (at == null) continue;
      final utc = at.isUtc ? at : at.toUtc();
      if (utc.isBefore(fromUtc) || !utc.isBefore(toUtc)) continue;
      final amount = int.tryParse('${data['amountMl'] ?? ''}') ?? 0;
      rows.add({
        'id': null,
        'eventType': 'water',
        'occurredAtUtc': data['occurredAtUtc'],
        'clientEventId': clientId,
        'payload': {'amountMl': amount},
        'amountMl': amount,
        '_waterLog': true,
        '_pending': true,
      });
    }
    return rows;
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      await _syncPendingWater();
      final from = _start.toUtc().toIso8601String();
      final to = _end.toUtc().toIso8601String();
      final results = await Future.wait([
        widget.api.getActivities(from: from, to: to),
        widget.api.getWater(from: from, to: to),
      ]);
      final activityRows = results[0];
      final waterRows = results[1];
      final knownClientIds = <String>{};
      final merged = <Map<String, dynamic>>[
        ...activityRows.map((e) => (e as Map).cast<String, dynamic>()),
        ...waterRows.map((e) {
          final row = (e as Map).cast<String, dynamic>();
          final amount = _waterAmount(row) ?? 0;
          final clientId = '${row['clientEventId'] ?? row['ClientEventId'] ?? ''}';
          if (clientId.isNotEmpty) knownClientIds.add(clientId);
          return <String, dynamic>{
            ...row,
            'eventType': 'water',
            'payload': {'amountMl': amount},
            'amountMl': amount,
            '_waterLog': true,
          };
        }),
      ];
      final pending = await WellnessOfflineStore.pending();
      merged.addAll(_pendingWaterForDay(pending, knownClientIds));
      if (!mounted) return;
      setState(() {
        items = merged
          ..sort(
            (a, b) =>
                '${a['occurredAtUtc']}'.compareTo('${b['occurredAtUtc']}'),
          );
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _open(String type) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddEventPage(api: widget.api, type: type, day: day),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(day, DateTime.now());
    final label = today
        ? 'Today, ${DateFormat('EEE d MMM').format(day)}'
        : DateFormat('EEE, d MMM y').format(day);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        Text(
          'Log your daily routine: meals, water, insulin, exercise, and other activities.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 12),
        _dateBar(label, today),
        const SizedBox(height: 14),
        Row(
          children: [
            _typeButton(Icons.restaurant_outlined, 'Meal', () => _open('meal')),
            _typeButton(
              Icons.water_drop_outlined,
              'Water',
              () => _open('water'),
            ),
            _typeButton(
              Icons.vaccines_outlined,
              'Insulin',
              () => _open('insulin'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _typeButton(
              Icons.directions_run,
              'Exercise',
              () => _open('exercise'),
            ),
            _typeButton(Icons.add, 'Other', () => _open('other')),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 18),
        _summary(),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's timeline",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${items.length} events',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading) const LinearProgressIndicator(color: AppColors.primary),
        if (!loading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nothing logged for this day. Tap a type above to add one.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ...items.map(_timelineTile),
        ],
      ),
    );
  }

  Widget _dateBar(String label, bool today) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => day = day.subtract(const Duration(days: 1)));
              _load();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: today
                ? null
                : () {
                    setState(() => day = day.add(const Duration(days: 1)));
                    _load();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final meals = items.where((e) => e['eventType'] == 'meal').toList();
    final water = items.where((e) => e['eventType'] == 'water').toList();
    final insulin = items.where((e) => e['eventType'] == 'insulin').toList();
    final exercise = items.where((e) => e['eventType'] == 'exercise').toList();
    final other = items.where((e) => e['eventType'] == 'other').toList();
    num carbs = 0, waterMl = 0, units = 0, minutes = 0;
    num? volume;
    for (final row in meals) {
      carbs +=
          num.tryParse('${(row['payload'] as Map?)?['carbohydratesGrams']}') ??
          0;
    }
    for (final row in insulin) {
      final payload = (row['payload'] as Map?) ?? {};
      units += num.tryParse('${payload['doseUnits']}') ?? 0;
      final ml = num.tryParse('${payload['volumeMl']}');
      if (ml != null) volume = (volume ?? 0) + ml;
    }
    for (final row in water) {
      waterMl += num.tryParse('${(row['payload'] as Map?)?['amountMl']}') ?? 0;
    }
    for (final row in exercise) {
      minutes +=
          num.tryParse('${(row['payload'] as Map?)?['durationMinutes']}') ?? 0;
    }
    final otherLabel = other.isEmpty
        ? 'None'
        : '${(other.last['payload'] as Map?)?['category'] ?? 'Note'}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Day summary",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _summaryRow(
            Icons.restaurant_outlined,
            'Meals',
            '${meals.length} entries',
            carbs == 0 ? '-' : '${carbs.toStringAsFixed(0)} g carbs',
          ),
          _summaryRow(
            Icons.water_drop_outlined,
            'Water',
            '${water.length} entries',
            waterMl == 0 ? '-' : '${waterMl.toStringAsFixed(0)} mL',
          ),
          _summaryRow(
            Icons.vaccines_outlined,
            'Insulin',
            '${insulin.length} doses',
            _insulinChip(units, volume),
          ),
          _summaryRow(
            Icons.directions_run,
            'Exercise',
            '${exercise.length} sessions',
            minutes == 0 ? '-' : '${minutes.toStringAsFixed(0)} min',
          ),
          _summaryRow(
            Icons.more_horiz_rounded,
            'Other',
            '${other.length} entries',
            otherLabel,
          ),
        ],
      ),
    );
  }

  String _insulinChip(num units, num? volume) {
    if (units == 0) return '-';
    final dose = units.toStringAsFixed(units % 1 == 0 ? 0 : 1);
    if (volume == null) return '$dose U';
    return '$dose U · ${volume.toStringAsFixed(2)} mL';
  }

  Widget _summaryRow(IconData icon, String title, String count, String chip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(count, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineTile(Map<String, dynamic> row) {
    final kind = '${row['eventType']}';
    final payload = (row['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final at = DateTime.tryParse('${row['occurredAtUtc']}')?.toLocal();
    final title = _title(kind, payload);
    final detail = _detail(kind, payload);
    final badge = _badge(kind, payload);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () async {
            if (row['_pending'] == true) {
              final clientId = '${row['clientEventId'] ?? ''}';
              final pending = await WellnessOfflineStore.pending();
              await WellnessOfflineStore.replace(
                pending
                    .where(
                      (e) =>
                          !(e['kind'] == 'water' &&
                              '${(e['data'] as Map?)?['clientEventId']}' ==
                                  clientId),
                    )
                    .toList(),
              );
              await _load();
              return;
            }
            final id = (row['id'] as num?)?.toInt();
            if (id == null) return;
            if (row['_waterLog'] == true) {
              await widget.api.deleteWater(id);
            } else {
              await widget.api.deleteActivity(id);
            }
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    at == null ? '' : DateFormat('h:mm a').format(at),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(_icon(kind), size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'meal':
        return Icons.restaurant_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'insulin':
        return Icons.vaccines_outlined;
      case 'exercise':
        return Icons.directions_run;
      default:
        return Icons.add;
    }
  }

  String _title(String kind, Map<String, dynamic> payload) {
    switch (kind) {
      case 'meal':
        return _cap('${payload['mealType']}');
      case 'water':
        return 'Water';
      case 'insulin':
        return 'Insulin';
      case 'exercise':
        return _cap('${payload['activity']}');
      default:
        return _cap('${payload['category']}');
    }
  }

  String _detail(String kind, Map<String, dynamic> payload) {
    switch (kind) {
      case 'meal':
        return '${payload['foodItems'] ?? ''}';
      case 'water':
        final amount = payload['amountMl'];
        return amount == null ? 'From reminder / log' : '$amount mL hydration';
      case 'insulin':
        return '${payload['name'] ?? ''} Â· ${payload['insulinType'] ?? ''}';
      case 'exercise':
        return _cap('${payload['intensity']} intensity');
      default:
        return '${payload['notes'] ?? ''}';
    }
  }

  String _badge(String kind, Map<String, dynamic> payload) {
    switch (kind) {
      case 'meal':
        return payload['carbohydratesGrams'] == null
            ? ''
            : '${payload['carbohydratesGrams']} g';
      case 'water':
        return payload['amountMl'] == null ? '' : '${payload['amountMl']} mL';
      case 'insulin':
        final units = payload['doseUnits'];
        final ml = payload['volumeMl'];
        return ml == null ? '$units U' : '$units U Â· $ml mL';
      case 'exercise':
        return '${payload['durationMinutes']} min';
      default:
        return '';
    }
  }

  String _cap(String value) {
    if (value.isEmpty || value == 'null') return '';
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _AddEventPage extends StatefulWidget {
  const _AddEventPage({
    required this.api,
    required this.type,
    required this.day,
  });
  final ApiService api;
  final String type;
  final DateTime day;
  @override
  State<_AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<_AddEventPage> {
  late String type = widget.type;
  String mealType = 'lunch';
  String activity = 'walking';
  String intensity = 'moderate';
  String otherCategory = 'medication';
  bool saving = false;
  late DateTime when = DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
    TimeOfDay.now().hour,
    TimeOfDay.now().minute,
  );
  final food = TextEditingController();
  final carbs = TextEditingController(text: '0');
  final waterAmount = TextEditingController(text: '250');
  final insulinName = TextEditingController();
  final insulinType = TextEditingController();
  final dose = TextEditingController(text: '1');
  final concentration = TextEditingController();
  final duration = TextEditingController(text: '30');
  final notes = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      food,
      carbs,
      waterAmount,
      insulinName,
      insulinType,
      dose,
      concentration,
      duration,
      notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _volumeMl {
    final units = double.tryParse(dose.text.trim());
    final conc = double.tryParse(concentration.text.trim());
    if (units == null || conc == null || conc <= 0) return null;
    return units / conc;
  }

  Future<void> _save() async {
    if (type == 'water') {
      final amount = int.tryParse(waterAmount.text.trim());
      if (amount == null || amount < 1 || amount > 10000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a water amount from 1 to 10,000 mL.'),
          ),
        );
        return;
      }
      setState(() => saving = true);
      try {
        await widget.api.createWater({
          'amountMl': amount,
          'occurredAtUtc': when.toUtc().toIso8601String(),
          'clientEventId': 'water-${DateTime.now().microsecondsSinceEpoch}',
        });
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      } finally {
        if (mounted) setState(() => saving = false);
      }
      return;
    }

    final payload = <String, dynamic>{};
    if (type == 'meal') {
      payload.addAll({
        'mealType': mealType,
        'foodItems': food.text.trim(),
        if ((num.tryParse(carbs.text.trim()) ?? 0) > 0)
          'carbohydratesGrams': num.tryParse(carbs.text.trim()),
      });
    } else if (type == 'insulin') {
      payload.addAll({
        'name': insulinName.text.trim(),
        'insulinType': insulinType.text.trim(),
        'doseUnits': num.tryParse(dose.text.trim()),
        if (_volumeMl != null)
          'concentrationUPerMl': num.tryParse(concentration.text.trim()),
      });
    } else if (type == 'exercise') {
      payload.addAll({
        'activity': activity,
        'durationMinutes': num.tryParse(duration.text.trim()),
        'intensity': intensity,
      });
    } else {
      payload.addAll({'category': otherCategory, 'notes': notes.text.trim()});
    }
    setState(() => saving = true);
    try {
      await widget.api.createActivity({
        'eventType': type,
        'payload': payload,
        'occurredAtUtc': when.toUtc().toIso8601String(),
        'clientEventId': 'activity-${DateTime.now().microsecondsSinceEpoch}',
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            PageTopBar(
              title: 'Add event',
              subtitle: 'Meal, water, insulin, or exercise',
              leading: PageTopAction(
                icon: Icons.chevron_left,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _picker(Icons.restaurant_outlined, 'Meal', 'meal'),
                _picker(Icons.water_drop_outlined, 'Water', 'water'),
                _picker(Icons.vaccines_outlined, 'Insulin', 'insulin'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _picker(Icons.directions_run, 'Exercise', 'exercise'),
                _picker(Icons.add, 'Other', 'other'),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _heading,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._fields(),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: Text(
                saving ? 'Saving...' : 'Save event',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _heading {
    switch (type) {
      case 'meal':
        return 'Meal details';
      case 'water':
        return 'Water details';
      case 'insulin':
        return 'Insulin details';
      case 'exercise':
        return 'Exercise details';
      default:
        return 'Other activity';
    }
  }

  Widget _picker(IconData icon, String label, String value) {
    final on = type == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => type = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: on ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? AppColors.primary : AppColors.surfaceBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: on ? Colors.white : AppColors.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: on ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (type) {
      case 'meal':
        return [
          _label('Meal name'),
          _chips(
            ['breakfast', 'lunch', 'dinner', 'snack'],
            mealType,
            (v) => mealType = v,
          ),
          _label('What did you eat?'),
          TextField(
            controller: food,
            decoration: _box('Chicken, rice, vegetables'),
          ),
          _label('Carbohydrates (g)'),
          _stepper(carbs, suffix: 'g'),
          _timeField(),
        ];
      case 'water':
        return [
          _label('Water amount (mL)'),
          _stepper(waterAmount, suffix: 'mL', step: 50),
          _timeField(),
        ];
      case 'insulin':
        return [
          _label('Insulin name'),
          TextField(controller: insulinName, decoration: _box('Name')),
          _label('Type'),
          TextField(
            controller: insulinType,
            decoration: _box('Rapid-acting, long-acting'),
          ),
          _label('Dose (U)'),
          _stepper(dose, suffix: 'U', step: 1),
          _label('Concentration, if known (U/mL)'),
          TextField(
            controller: concentration,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: _box('Optional'),
          ),
          if (_volumeMl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Volume ${_volumeMl!.toStringAsFixed(3)} mL',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          _timeField(),
        ];
      case 'exercise':
        return [
          _label('Activity'),
          _chips(
            ['walking', 'running', 'cycling', 'gym'],
            activity,
            (v) => activity = v,
          ),
          _label('Duration (min)'),
          _stepper(duration, suffix: 'min', step: 5),
          _label('Intensity'),
          _chips(['low', 'moderate', 'high'], intensity, (v) => intensity = v),
          _timeField(),
        ];
      default:
        return [
          _label('Kind'),
          _chips(
            ['medication', 'sleep', 'stress', 'illness', 'note'],
            otherCategory,
            (v) => otherCategory = v,
          ),
          _label('Notes'),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: _box('What happened?'),
          ),
          _timeField(),
        ];
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  InputDecoration _box(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.surfaceBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.surfaceBorder),
    ),
  );

  Widget _chips(
    List<String> values,
    String selected,
    void Function(String) onPick,
  ) {
    return Wrap(
      spacing: 8,
      children: values.map((value) {
        final on = value == selected;
        return ChoiceChip(
          label: Text(_cap(value)),
          selected: on,
          selectedColor: AppColors.primarySoft,
          labelStyle: TextStyle(
            color: on ? AppColors.primaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => setState(() => onPick(value)),
        );
      }).toList(),
    );
  }

  Widget _stepper(
    TextEditingController controller, {
    required String suffix,
    num step = 5,
  }) {
    void bump(num delta) {
      final current = num.tryParse(controller.text) ?? 0;
      final next = current + delta;
      if (next < 0) return;
      controller.text = next % 1 == 0
          ? next.toStringAsFixed(0)
          : next.toString();
      setState(() {});
    }

    return Row(
      children: [
        _round(Icons.remove, () => bump(-step)),
        Expanded(
          child: Text(
            '${controller.text.isEmpty ? '0' : controller.text} $suffix',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        _round(Icons.add, () => bump(step)),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _timeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Time'),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(when),
            );
            if (time == null) return;
            setState(
              () => when = DateTime(
                when.year,
                when.month,
                when.day,
                time.hour,
                time.minute,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(when),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _cap(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
