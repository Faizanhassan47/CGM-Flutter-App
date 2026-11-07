import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../state/app_controller.dart';
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

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );

  static const _tabs = <({IconData icon, IconData activeIcon, String label})>[
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.schedule_rounded, activeIcon: Icons.schedule_rounded, label: 'History'),
    (icon: Icons.event_note_outlined, activeIcon: Icons.event_note_rounded, label: 'Activities'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final GlobalKey _navKey = GlobalKey();
  late final AnimationController _pillController;
  late final List<double> _pillWidths;

  int _selected = 0;
  int _lastHaptic = 0;
  double _pillPage = 0;
  bool _scrubbing = false;

  @override
  void initState() {
    super.initState();
    _pillWidths = [for (final tab in _tabs) _widthForLabel(tab.label)];
    _pillController = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(() {
        if (_scrubbing) return;
        setState(() => _pillPage = _pillController.value);
      });
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  static double _widthForLabel(String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return 16 + 22 + 8 + painter.width + 16;
  }

  void _selectTab(int index, {bool animate = true}) {
    final target = index.clamp(0, _tabs.length - 1);
    if (_selected != target) {
      setState(() => _selected = target);
      HapticFeedback.selectionClick();
      _lastHaptic = target;
    }
    if (animate) {
      _pillController
          .animateTo(
            target.toDouble(),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            if (mounted) setState(() => _pillPage = target.toDouble());
          });
    } else {
      _pillController.value = target.toDouble();
      _pillPage = target.toDouble();
    }
  }

  void _onSwitchTab(int index) {
    final page = switch (index) {
      4 => 3,
      _ => index,
    };
    _selectTab(page);
  }

  void _scrubTo(Offset globalPosition) {
    final box = _navKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final x = box.globalToLocal(globalPosition).dx.clamp(0.0, box.size.width);
    final page = (x / box.size.width) * (_tabs.length - 1);
    final nearest = page.round().clamp(0, _tabs.length - 1);
    setState(() {
      _scrubbing = true;
      _pillPage = page;
      if (_selected != nearest) {
        _selected = nearest;
      }
    });
    if (nearest != _lastHaptic) {
      _lastHaptic = nearest;
      HapticFeedback.selectionClick();
    }
  }

  void _endScrub() {
    _scrubbing = false;
    _selectTab(_selected, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selected,
        children: [
          HomeScreen(controller: widget.controller, onSwitchTab: _onSwitchTab),
          HistoryScreen(controller: widget.controller),
          DailyActivitiesScreen(api: widget.controller.api),
          ProfileScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SafeArea(
          top: false,
          child: Container(
            key: _navKey,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _tabs.length;
                final page = _pillPage.clamp(0.0, (_tabs.length - 1).toDouble());
                final lower = page.floor().clamp(0, _tabs.length - 1);
                final upper = page.ceil().clamp(0, _tabs.length - 1);
                final t = lower == upper ? 0.0 : page - lower;
                final width = _pillWidths[lower] * (1 - t) + _pillWidths[upper] * t;
                final center = (lower + t) * slot + slot / 2;
                final left = (center - width / 2).clamp(0.0, constraints.maxWidth - width);
                final labelIndex = page.round().clamp(0, _tabs.length - 1);
                final labelOpacity = (1 - (page - labelIndex).abs() * 2).clamp(0.0, 1.0);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final index = (details.localPosition.dx / constraints.maxWidth * _tabs.length)
                        .floor()
                        .clamp(0, _tabs.length - 1);
                    _selectTab(index);
                  },
                  onHorizontalDragStart: (details) => _scrubTo(details.globalPosition),
                  onHorizontalDragUpdate: (details) => _scrubTo(details.globalPosition),
                  onHorizontalDragEnd: (_) => _endScrub(),
                  onHorizontalDragCancel: _endScrub,
                  child: Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: width,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_tabs[labelIndex].activeIcon, size: 22, color: Colors.white),
                              SizedBox(width: 8 * labelOpacity),
                              Opacity(
                                opacity: labelOpacity,
                                child: Text(_tabs[labelIndex].label, style: _labelStyle),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _tabs.length; i++)
                            Expanded(
                              child: Center(
                                child: Opacity(
                                  opacity: labelIndex == i ? 0 : 1,
                                  child: Icon(
                                    _tabs[i].icon,
                                    size: 22,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
