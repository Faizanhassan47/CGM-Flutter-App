import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.showSubtitle = true});
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/images/logo.svg', width: 82, height: 82),
        const SizedBox(height: AppSpacing.md),
        const Text('Aima', style: AppTextStyles.display),
        if (showSubtitle) ...[
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Stay informed, stay in control.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ],
    );
  }
}
