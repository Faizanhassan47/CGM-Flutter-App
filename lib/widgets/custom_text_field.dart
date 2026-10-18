import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CustomUnderlineField extends StatelessWidget {
  const CustomUnderlineField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.body.copyWith(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            errorText: errorText,
            errorMaxLines: 2,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w400,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 24,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      prefixIcon,
                      size: 20,
                      color: AppTheme.primaryPurple,
                    ),
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}
