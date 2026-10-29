import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String selectedFilter = 'All'; // 'All', 'Critical', 'Warning'

  bool _isCritical(dynamic rawAlert) {
    if (rawAlert is! Map) return false;
    final alert = Map<String, dynamic>.from(rawAlert);
    final flag = alert['isCritical'] ?? alert['IsCritical'];
    final severity = (alert['severity'] ?? alert['Severity'] ?? '')
        .toString()
        .toLowerCase();
    return flag == true || flag == 1 || flag == '1' || severity == 'critical';
  }

  @override
  void initState() {
    super.initState();
    widget.controller.loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final rawAlerts = widget.controller.alerts;
    final alerts = rawAlerts.where((a) {
      final critical = _isCritical(a);
      if (selectedFilter == 'Critical') {
        return critical;
      }
      if (selectedFilter == 'Warning') {
        return !critical;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: widget.controller.loadAlerts,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alerts',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkPurple,
                      letterSpacing: -0.5,
                    ),
                  ),
                
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: ['All', 'Critical', 'Warning'].map((f) {
                  final isSelected = selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedFilter = f),
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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Container(
                        padding: AppInsets.all18,
                        decoration: const BoxDecoration(
                          color: AppTheme.lightPurpleBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 38,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No alerts right now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your glucose telemetry has been stable.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...alerts.map((a) {
                  final isCritical = _isCritical(a);
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
                  final timeStr = DateFormat('h:mm a MMM d')
                      .format(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.darkPurple,
                                    ),
                                  ),
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
                                msg,
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
            ],
          ),
        ),
      ),
    );
  }
}
