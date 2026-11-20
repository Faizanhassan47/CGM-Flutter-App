import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';
import '../../services/notification_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/page_top_bar.dart';
import 'alert_category.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String selectedFilter = 'All'; // 'All', 'Critical', 'Warning'
  late bool criticalAlerts;
  late bool sensorAlerts;
  late bool reportReminders;
  static const _pageSize = 25;

  @override
  void initState() {
    super.initState();
    criticalAlerts = widget.controller.criticalAlerts;
    sensorAlerts = widget.controller.sensorAlerts;
    reportReminders = widget.controller.reportReminders;
    unawaited(widget.controller.loadAlerts(pageSize: _pageSize));
  }

  void _savePreferences() {
    widget.controller.setPreferences(
      critical: criticalAlerts,
      sensor: sensorAlerts,
      reminders: reportReminders,
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear alert history?'),
        content: const Text(
          'This removes the alerts shown here. New alerts will still appear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.clearAlertHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not clear alerts: $e')));
    }
  }

  Future<void> _openSettings() async {
    var mealEnabled = true;
    var waterEnabled = true;
    List schedules = const [];
    try {
      final response = await widget.controller.api.getWellnessReminders();
      final settings = (response['settings'] as Map?) ?? {};
      mealEnabled = settings['mealEnabled'] != false;
      waterEnabled = settings['waterEnabled'] != false;
      schedules = (response['schedules'] as List?) ?? const [];
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveWellness() async {
              final response = await widget.controller.api
                  .updateWellnessReminders({
                    'mealEnabled': mealEnabled,
                    'waterEnabled': waterEnabled,
                  });
              final settings =
                  (response['settings'] as Map?)?.cast<String, dynamic>() ??
                  {'mealEnabled': mealEnabled, 'waterEnabled': waterEnabled};
              final nextSchedules =
                  (response['schedules'] as List?) ?? schedules;
              await NotificationService.instance.scheduleWellness(
                settings: settings,
                schedules: nextSchedules,
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Critical glucose alerts'),
                    value: criticalAlerts,
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppTheme.primaryPurple,
                    onChanged: (value) {
                      setState(() => criticalAlerts = value);
                      setSheetState(() {});
                      _savePreferences();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sensor and connection alerts'),
                    value: sensorAlerts,
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppTheme.primaryPurple,
                    onChanged: (value) {
                      setState(() => sensorAlerts = value);
                      setSheetState(() {});
                      _savePreferences();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Report reminders'),
                    value: reportReminders,
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppTheme.primaryPurple,
                    onChanged: (value) {
                      setState(() => reportReminders = value);
                      setSheetState(() {});
                      _savePreferences();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meal reminders'),
                    value: mealEnabled,
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppTheme.primaryPurple,
                    onChanged: (value) {
                      setSheetState(() => mealEnabled = value);
                      saveWellness();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Water reminders'),
                    value: waterEnabled,
                    activeThumbColor: AppColors.surface,
                    activeTrackColor: AppTheme.primaryPurple,
                    onChanged: (value) {
                      setSheetState(() => waterEnabled = value);
                      saveWellness();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  AlertCategory _category(dynamic alert) =>
      alert is Map ? classifyAlert(alert) : AlertCategory.warning;

  Map<String, dynamic>? _liveGlucoseAlert() {
    final sample = widget.controller.connection.name == 'connected'
        ? widget.controller.latest
        : null;
    final raw = sample?.value;
    if (raw == null) return null;
    final mg = raw > 30 ? raw : raw * 18.0182;
    final low = mg <= widget.controller.urgentLowThreshold;
    final high = mg >= widget.controller.urgentHighThreshold;
    if (!low && !high) return null;
    return {
      'id': 'glucose:live',
      'title': low
          ? 'Critical urgent low glucose'
          : 'Critical urgent high glucose',
      'message': '${mg.round()} mg/dL is outside your urgent range.',
      'severity': 'critical',
      'timestamp': (sample!.measuredAt).toIso8601String(),
      'isRead': false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final live = _liveGlucoseAlert();
          final alreadyListed =
              live != null &&
              widget.controller.alerts.any(
                (a) => '${a['title'] ?? a['Title']}' == live['title'],
              );
          final alerts =
              [
                  if (live != null &&
                      !alreadyListed &&
                      selectedFilter != 'Warning')
                    live,
                  ...widget.controller.alerts,
                ].where((a) {
                  final category = _category(a);
                  if (selectedFilter == 'Critical') {
                    return category == AlertCategory.critical;
                  }
                  if (selectedFilter == 'Warning') {
                    return category == AlertCategory.warning;
                  }
                  return true;
                }).toList()
                ..sort((a, b) {
                  final criticalA = _category(a) == AlertCategory.critical;
                  final criticalB = _category(b) == AlertCategory.critical;
                  if (criticalA != criticalB) return criticalA ? -1 : 1;
                  final timeA =
                      DateTime.tryParse(
                        '${a['timestamp'] ?? a['AlertTime'] ?? ''}',
                      ) ??
                      DateTime(0);
                  final timeB =
                      DateTime.tryParse(
                        '${b['timestamp'] ?? b['AlertTime'] ?? ''}',
                      ) ??
                      DateTime(0);
                  return timeB.compareTo(timeA);
                });
          return SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryPurple,
              onRefresh: () =>
                  widget.controller.loadAlerts(pageSize: _pageSize),
              child: ListView(
                scrollCacheExtent: ScrollCacheExtent.pixels(
                  UiPerf.listCacheExtent(context),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  PageTopBar(
                    title: 'Notifications',
                    subtitle: 'Glucose, sensor, and reminder alerts',
                    trailing: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        fixedSize: const Size(38, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'settings') _openSettings();
                        if (value == 'remove') _clearHistory();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'settings',
                          child: Text('Settings'),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove notifications'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: ['All', 'Critical', 'Warning'].map((f) {
                      final isSelected = selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedFilter = f);
                            unawaited(
                              widget.controller.loadAlerts(
                                page: 1,
                                pageSize: _pageSize,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple
                                  : AppColors.surface,
                              borderRadius: AppRadii.r20,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryPurple
                                    : AppPalette.hexFFE5DCF4,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.surface
                                    : AppTheme.darkPurple,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  if (alerts.isEmpty)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 92,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your notifications live here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              'Glucose, sensor, and reminder alerts will show up in this list.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _openSettings,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Notification settings'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...alerts.map((a) {
                      final isCritical = _category(a) == AlertCategory.critical;
                      final title =
                          a['title'] ?? a['Title'] ?? 'Glucose Notification';
                      final msg =
                          a['message'] ??
                          a['Message'] ??
                          'Reading in target corridor.';
                      final isRead = a['isRead'] == 1 || a['isRead'] == true;
                      final timeRaw =
                          a['timestamp'] ??
                          a['AlertTime'] ??
                          DateTime.now().toIso8601String();
                      final timeStr = DateFormat('h:mm a MMM d').format(
                        DateTime.tryParse(timeRaw.toString()) ?? DateTime.now(),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: AppInsets.all16,
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppColors.surface
                              : AppPalette.hexFFFAF8FE,
                          borderRadius: AppRadii.r18,
                          border: Border.all(
                            color: isRead
                                ? AppPalette.hexFFEFEBF6
                                : AppTheme.purpleBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: AppInsets.all10,
                              decoration: BoxDecoration(
                                color: isCritical
                                    ? AppTheme.dangerBg
                                    : AppTheme.lightPurpleBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCritical
                                    ? Icons.warning_amber_rounded
                                    : Icons.notifications_active_outlined,
                                color: isCritical
                                    ? AppTheme.dangerRed
                                    : AppTheme.primaryPurple,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$title',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.darkPurple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$msg',
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (widget.controller.alertsHasMore) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: widget.controller.alertsLoadingMore
                            ? null
                            : () => unawaited(
                                widget.controller.loadAlerts(
                                  page: widget.controller.alertsPage + 1,
                                  pageSize: _pageSize,
                                  append: true,
                                ),
                              ),
                        child: widget.controller.alertsLoadingMore
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load more alerts'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
