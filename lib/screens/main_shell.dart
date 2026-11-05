import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../state/app_controller.dart';
import 'alerts/alerts_screen.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'wellness/daily_activities_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;
  int _previousIndex = 0;

  void _onSwitchTab(int index) {
    if (index == currentIndex) return;
    setState(() {
      _previousIndex = currentIndex;
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(controller: widget.controller, onSwitchTab: _onSwitchTab),
      HistoryScreen(controller: widget.controller),
      DailyActivitiesScreen(api: widget.controller.api),
      AlertsScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final forward = currentIndex >= _previousIndex;
          final incoming = (child.key as ValueKey<int>?)?.value == currentIndex;
          final direction = forward ? 1.0 : -1.0;
          final begin = incoming ? Offset(0.05 * direction, 0) : Offset(-0.03 * direction, 0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SafeArea(
          top: false,
          child: Container(
            height: 62,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(31),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 22, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _item(1, Icons.schedule_rounded, Icons.schedule_rounded, 'History'),
                _item(2, Icons.event_note_outlined, Icons.event_note_rounded, 'Activities'),
                _item(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label) {
    final selected = currentIndex == index;
    final child = InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => _onSwitchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: selected ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(selected ? activeIcon : icon, size: 22, color: selected ? Colors.white : AppColors.textSecondary),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
    if (selected) return child;
    return Expanded(child: child);
  }
}
