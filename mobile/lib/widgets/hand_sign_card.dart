// lib/widgets/hand_sign_card.dart
//
// ASLive — HandSignCard widget
// =============================
// Equivalent to the `.hand-sign-item` in index.html.
// Displays an ASL sign image with its letter label beneath it.
// The image path can be either an asset or a network URL.
// Used on the landing screen to spell "ASLive" with sign images.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HandSignCard extends StatelessWidget {
  final String letter;
  final String imageAsset; // asset path, e.g. 'assets/images/sign_a.png'

  const HandSignCard({
    super.key,
    required this.letter,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image — matches .hand-sign-img: 90×90, border-radius 8
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Image.asset(
            imageAsset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cardLightTan,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Letter label — matches .hand-sign-letter
        Text(
          letter,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}
