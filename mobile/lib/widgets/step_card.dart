// lib/widgets/step_card.dart
//
// ASLive — StepCard widget
// =========================
// Equivalent to `.step-card` in index.html / style.css.
// Shows an icon, title, and description in the "How It Works" section.
// Matches: background-color var(--text-light), padding 2rem, border-radius 12px,
//          box-shadow 0 4px 12px rgba(0,0,0,0.05).

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const StepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0,0,0,0.05)
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon — matches .step-icon color: var(--secondary-tan)
          Icon(
            icon,
            size: 36,
            color: AppColors.secondaryTan,
          ),
          const SizedBox(height: AppSpacing.md),
          // Title — matches .step-title: 1.2rem, bold, color: var(--dark-brown)
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Description — matches .step-desc: 0.95rem, color #555
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF555555),
              height: 1.5,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}
