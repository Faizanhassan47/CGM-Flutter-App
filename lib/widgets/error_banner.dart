import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key, this.onClose});
  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecorations.errorBanner,
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.primaryPurple,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.body)),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
