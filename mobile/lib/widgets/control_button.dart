// lib/widgets/control_button.dart
//
// ASLive — ControlButton widget
// ===============================
// Equivalent to `.control-btn` in style.css.
// A pill-shaped action button used in the controls-bar on the translate screen.
// Matches: padding 0.75rem 1.5rem, border-radius 8px,
//          background-color var(--text-light), color var(--text-dark),
//          box-shadow 0 2px 4px rgba(0,0,0,0.1).

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isPrimary ? AppColors.primaryTan : AppColors.textLight;
    final fgColor =
        isPrimary ? AppColors.textLight : AppColors.textDark;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: 2,
      shadowColor: const Color(0x1A000000),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fgColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
