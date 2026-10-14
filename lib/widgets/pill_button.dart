import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum PillButtonVariant { purple, cyan, outlineCyan, danger }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PillButtonVariant.purple,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String text;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final Widget? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case PillButtonVariant.purple:
        bg = AppColors.primary;
        fg = AppColors.surface;
        break;
      case PillButtonVariant.cyan:
        bg = AppColors.accent;
        fg = AppColors.surface;
        break;
      case PillButtonVariant.outlineCyan:
        bg = AppColors.surface;
        fg = AppColors.primaryDark;
        border = const BorderSide(color: AppColors.accent, width: 2);
        break;
      case PillButtonVariant.danger:
        bg = AppColors.danger;
        fg = AppColors.surface;
        break;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: AppColors.transparent,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text, style: AppTextStyles.button.copyWith(color: fg)),
                ],
              ),
      ),
    );
  }
}
