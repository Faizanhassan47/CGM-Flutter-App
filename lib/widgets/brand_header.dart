import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.showSubtitle = true});
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/circle_logo.png',
          width: 300,
          fit: BoxFit.contain,
          semanticLabel: 'Circle Continuous Glucose Monitoring',
        ),
        const SizedBox(height: AppSpacing.md),
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
