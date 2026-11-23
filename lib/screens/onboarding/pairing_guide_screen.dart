import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';
import '../../state/app_controller.dart';
import 'device_setup_screen.dart';

/// Shows the apply-sensor guide, then opens device setup if the user finishes it.
Future<void> openDeviceSetup(BuildContext context, AppController controller) async {
  final ready = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const PairingGuideScreen()),
  );
  if (!context.mounted || ready != true) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DeviceSetupScreen(controller: controller)),
  );
}

/// Illustrated apply-sensor guide shown before Bluetooth pairing starts.
class PairingGuideScreen extends StatefulWidget {
  const PairingGuideScreen({super.key});

  @override
  State<PairingGuideScreen> createState() => _PairingGuideScreenState();
}

class _PairingGuideScreenState extends State<PairingGuideScreen> {
  static const _pageCount = 3;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goPage(int page) {
    if (page < 0 || page >= _pageCount || page == _page) return;
    setState(() => _page = page);
    // Always use a positive duration — PageController rejects Duration.zero,
    // and jumpToPage was a no-op on some devices after the low-end opt path.
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _goPage(_page + 1);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            if (_page > 0) {
              _goPage(_page - 1);
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
        title: const Text(
          'Pairing guide',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              children: List.generate(_pageCount, (i) {
                final active = i <= _page;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == _pageCount - 1 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              allowImplicitScrolling: false,
              onPageChanged: (i) {
                if (_page == i) return;
                setState(() => _page = i);
              },
              itemBuilder: (context, index) {
                final page = switch (index) {
                  0 => const _CleanSitePage(),
                  1 => const _AssemblePage(),
                  _ => const _InsertPage(),
                };
                return RepaintBoundary(child: page);
              },
            ),
          ),
          Container(
            color: const Color(0xFFF6F7F9),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _next,
                    child: Text(
                      'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Need help?'),
                        content: const Text(
                          'Follow each step on a clean, flat surface. '
                          'If the sensor does not click into place, stop and '
                          'contact support before trying again.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Need help?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanSitePage extends StatelessWidget {
  const _CleanSitePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: const [
        Text(
          'Clean the insertion site',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select the correct site and clean it thoroughly to ensure stable sensor operation',
          style: TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF6B7280)),
        ),
        SizedBox(height: 16),
        _StepCard(
          number: '1',
          title: 'Select insertion site',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _SiteTile(label: 'Abdomen', arm: false)),
                  SizedBox(width: 10),
                  Expanded(child: _SiteTile(label: 'Back of upper arm', arm: true)),
                ],
              ),
              SizedBox(height: 14),
              Text(
                'Abdomen',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                'Abdomen: within 5cm around the navel, avoiding belts, scars, tattoos, bony prominences, and injection sites',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF374151)),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a spot that can be pinched easily.',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(
          text: 'Back of upper arm is only for users aged 13 and above',
        ),
        SizedBox(height: 12),
        _StepCard(
          number: '2',
          title: 'Cleaning steps',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.clean),
              SizedBox(height: 12),
              Text(
                'Wipe outward in circles from the center with an alcohol pad and let the skin air dry naturally. Do not blow with your mouth or fan with your hand.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(
          text:
              'Do not apply lotion, oil, or sunscreen after cleaning, as this may affect adhesion.',
        ),
      ],
    );
  }
}

class _AssemblePage extends StatelessWidget {
  const _AssemblePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: const [
        Text(
          'Apply Sensor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please follow the steps below to complete the assembly of the sensor and transmitter on a flat tabletop.',
          style: TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF6B7280)),
        ),
        SizedBox(height: 16),
        _StepCard(
          number: '1',
          title: 'Prepare components',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.prepare),
              SizedBox(height: 12),
              Text(
                'Open the sensor kit package and take out the sensor kit and bottom tray.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(
          text:
              'Do not touch the top button of the applicator or the adhesive surface on the bottom.',
        ),
        SizedBox(height: 12),
        _StepCard(
          number: '2',
          title: 'Mark alignment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.align),
              SizedBox(height: 12),
              Text(
                'Secure the tray on a flat surface and align the blue-marked slot on the sensor kit with the blue mark on the tray.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _StepCard(
          number: '3',
          title: 'Press down',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.press),
              SizedBox(height: 12),
              Text(
                'Secure the bottom tray to the tabletop, press firmly on the white housing with both hands to push the sensor assembly into the tray until a "click" is heard and it cannot be pressed further.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _StepCard(
          number: '4',
          title: 'Unlock device',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.unlock),
              SizedBox(height: 12),
              Text(
                'Turn the safety knob on top of the applicator in the direction of the arrow to unlock it.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(text: 'Please do not press the top white button.'),
        SizedBox(height: 12),
        _StepCard(
          number: '5',
          title: 'Lift the sensor kit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.lift),
              SizedBox(height: 12),
              Text(
                'Hold the sensor assembly by the concave sides on both sides, and lift it vertically out of the tray.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(
          text:
              'Do not touch the bottom adhesive surface, do not press the top white button.',
        ),
      ],
    );
  }
}

class _InsertPage extends StatelessWidget {
  const _InsertPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: const [
        Text(
          'Apply Sensor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'After placing the sensor on the cleaned insertion site, follow the steps below to complete sensor insertion.',
          style: TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF6B7280)),
        ),
        SizedBox(height: 16),
        _StepCard(
          number: '1',
          title: 'Complete insertion',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.insert),
              SizedBox(height: 12),
              Text(
                'Place the applicator firmly against the application site. Press the blue button on top. After you hear a click, the sensor has been inserted. Gently lift the applicator straight up and away from the skin.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _StepCard(
          number: '2',
          title: 'Reinforcement patch',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Illustration(kind: _Art.patch),
              SizedBox(height: 12),
              Text(
                'Gently press and smooth the medical adhesive tape with your fingers to secure it to the skin. If needed, apply the reinforcing adhesive patch as shown.',
                style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF374151)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _WarnBox(
          text: 'Gently press the surrounding adhesive tape for 15-30 s.',
        ),
        SizedBox(height: 12),
        _CautionBox(
          title: 'Precautions',
          text: 'Dispose of medical waste according to local regulations',
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lowEnd = UiPerf.isLowEndLayout(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: lowEnd ? Border.all(color: const Color(0xFFE8ECF2)) : null,
        boxShadow: lowEnd
            ? null
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WarnBox extends StatelessWidget {
  const _WarnBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF5A623), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE6A23C),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CautionBox extends StatelessWidget {
  const _CautionBox({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}

class _SiteTile extends StatelessWidget {
  const _SiteTile({required this.label, required this.arm});
  final String label;
  final bool arm;

  @override
  Widget build(BuildContext context) {
    final asset = arm
        ? 'assets/images/guide_site_arm.jpg'
        : 'assets/images/guide_site_abdomen.jpg';
    final cacheH = UiPerf.cachePx(context, 140);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            asset,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheHeight: cacheH,
            filterQuality: UiPerf.imageFilter(context),
            gaplessPlayback: true,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

enum _Art { clean, prepare, align, press, unlock, lift, insert, patch }

class _Illustration extends StatelessWidget {
  const _Illustration({required this.kind});
  final _Art kind;

  String get _asset {
    switch (kind) {
      case _Art.clean:
        return 'assets/images/guide_clean.jpg';
      case _Art.prepare:
        return 'assets/images/guide_prepare.jpg';
      case _Art.align:
        return 'assets/images/guide_align.jpg';
      case _Art.press:
        return 'assets/images/guide_press.jpg';
      case _Art.unlock:
        return 'assets/images/guide_unlock.jpg';
      case _Art.lift:
        return 'assets/images/guide_lift.jpg';
      case _Art.insert:
        return 'assets/images/guide_insert.jpg';
      case _Art.patch:
        return 'assets/images/guide_patch.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheH = UiPerf.cachePx(context, 170);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        _asset,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheHeight: cacheH,
        filterQuality: UiPerf.imageFilter(context),
        gaplessPlayback: true,
      ),
    );
  }
}
