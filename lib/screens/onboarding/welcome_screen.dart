import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    _Slide(
      title: 'Real-time glucose, monitor anytime',
      subtitle: '15-day accurate glucose monitoring on your phone.',
      icon: Icons.monitor_heart_outlined,
      value: '104',
    ),
    _Slide(
      title: 'Water reminders',
      subtitle: 'Set a daily goal and get hydration reminders through the day.',
      icon: Icons.water_drop_outlined,
      value: '250 ml',
    ),
    _Slide(
      title: 'Meal reminders',
      subtitle: 'Log meals and get reminders for breakfast, lunch, and dinner.',
      icon: Icons.restaurant_outlined,
      value: 'Lunch',
    ),
    _Slide(
      title: 'Generate reports',
      subtitle: 'Create detailed, AGP, and overnight reports, then share a PDF.',
      icon: Icons.description_outlined,
      value: 'AGP',
    ),
    _Slide(
      title: 'Diet assistant',
      subtitle: 'Ask for meal guidance based on your recent glucose trends.',
      icon: Icons.chat_bubble_outline,
      value: 'Ask',
    ),
    _Slide(
      title: 'Alerts that matter',
      subtitle: 'High, low, and night-time alerts when glucose leaves your range.',
      icon: Icons.notifications_active_outlined,
      value: 'Low',
    ),
    _Slide(
      title: 'Family circle',
      subtitle: 'Share readings and alerts with the people who look after you.',
      icon: Icons.groups_outlined,
      value: 'Family',
    ),
    _Slide(
      title: 'Sleep monitoring',
      subtitle: 'Review overnight glucose, including dawn rise and night lows.',
      icon: Icons.bedtime_outlined,
      value: 'Night',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _page.nextPage(
        duration: UiPerf.pageTransition(context),
        curve: Curves.easeOut,
      );
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final skipMotion = UiPerf.skipDecorativeMotion(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _pages.length,
                  allowImplicitScrolling: false,
                  onPageChanged: (value) {
                    if (_index == value) return;
                    setState(() => _index = value);
                  },
                  itemBuilder: (context, index) => RepaintBoundary(
                    child: _SlideView(
                      slide: _pages[index],
                      lowEnd: skipMotion,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final active = index == _index;
                  final dot = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 8 : 7,
                    height: active ? 8 : 7,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.primaryBorder,
                      shape: BoxShape.circle,
                    ),
                  );
                  if (skipMotion) return dot;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 8 : 7,
                    height: active ? 8 : 7,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.primaryBorder,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE10600),
                    foregroundColor: AppColors.surface,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _next,
                  child: Text(_index == _pages.length - 1 ? 'Start Your Experience' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.subtitle, required this.icon, required this.value});
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.lowEnd});
  final _Slide slide;
  final bool lowEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 36),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          slide.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 36),
        Expanded(child: _Illustration(slide: slide, lowEnd: lowEnd)),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide, required this.lowEnd});
  final _Slide slide;
  final bool lowEnd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 230,
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 28, child: _MiniBar(icon: slide.icon)),
            Positioned(
              top: 78,
              child: Container(
                width: 190,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: lowEnd
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                  border: lowEnd
                      ? Border.all(color: const Color(0xFFE8ECF2))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slide.value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ),
            const Positioned(bottom: 28, child: _ChartCard()),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          CircleAvatar(radius: 10, backgroundColor: AppColors.primarySoft, child: Icon(icon, size: 12, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFE8ECF2), borderRadius: BorderRadius.circular(99)))),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF3F5F8), borderRadius: BorderRadius.circular(14)),
      child: const CustomPaint(painter: _SparkPainter()),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.9, size.width * 0.38, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.15, size.width * 0.7, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.84, size.height * 0.58, size.width, size.height * 0.48);
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.55), 3.5, Paint()..color = AppColors.textPrimary);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.38), 4, Paint()..color = const Color(0xFFFFB020));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
