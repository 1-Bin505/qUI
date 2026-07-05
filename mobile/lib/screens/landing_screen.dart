// lib/screens/landing_screen.dart
//
// ASLive — Landing Screen
// ========================
// Flutter port of templates/index.html + static/css/style.css.
//
// Layout hierarchy (matches HTML):
//   body.landing-page
//   └─ main#landing-main
//      ├─ section#hero-section        ← gradient hero, hand signs, info card, CTA
//      ├─ section#about-section       ← "How It Works" step cards
//      └─ footer#landing-footer       ← copyright
//
// CSS mapping:
//   .landing-page #hero-section  → gradient 135deg bgColor → primaryTan, min-height 80vh
//   .hero-container              → Column, max-width 1000, gap 2rem
//   #hand-signs-row              → Row (Wrap on small screens), gap 1rem
//   #info-card                   → Container with cardBrown bg, text-light color
//   #cta-button                  → ElevatedButton pill shape
//   #about-section               → Column, padding 4rem
//   .step-card                   → StepCard widget (see widgets/step_card.dart)
//   #landing-footer              → centered text, color #777

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_sign_card.dart';
import '../widgets/step_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HERO SECTION ───────────────────────────────────────
            _buildHeroSection(context),

            // ─── ABOUT / HOW IT WORKS ───────────────────────────────
            _buildAboutSection(context),

            // ─── FOOTER ─────────────────────────────────────────────
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Hero Section
  // Matches: background linear-gradient(135deg, bgColor 0%, primaryTan 100%)
  //          min-height: 80vh, centered content
  // ==========================================================================
  Widget _buildHeroSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgColor, AppColors.primaryTan],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── ASL Hand Sign Illustrations Row ──
            // Matches #hand-signs-row: flex, gap 1rem, wrap
            _buildHandSignsRow(),

            const SizedBox(height: AppSpacing.xl),

            // ── Info Card ──
            // Matches #info-card: bg cardBrown, text textLight, padding 2rem, radius 12px
            _buildInfoCard(),

            const SizedBox(height: AppSpacing.xl),

            // ── CTA Button ──
            // Matches #cta-button: pill shape, bg textLight, color textDark
            _buildCtaButton(context),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Hand signs row spelling "ASLive"
  // --------------------------------------------------------------------------
  Widget _buildHandSignsRow() {
    // Mapping letters to their sign image assets (from static/images/)
    const signs = [
      {'letter': 'A', 'asset': 'assets/images/sign_a.png'},
      {'letter': 'S', 'asset': 'assets/images/sign_s.png'},
      {'letter': 'L', 'asset': 'assets/images/sign_l.png'},
      {'letter': 'i', 'asset': 'assets/images/sign_i.png'},
      {'letter': 'v', 'asset': 'assets/images/sign_v.png'},
      {'letter': 'e', 'asset': 'assets/images/sign_e.png'},
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
      children: signs
          .map((s) => HandSignCard(
                letter: s['letter']!,
                imageAsset: s['asset']!,
              ))
          .toList(),
    );
  }

  // --------------------------------------------------------------------------
  // Info card — brown background with light text
  // --------------------------------------------------------------------------
  Widget _buildInfoCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardBrown,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // rgba(0,0,0,0.1)
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Text(
        'ASLive bridges the communication gap between the deaf and hearing '
        'communities. Using real-time AI-powered sign language recognition, '
        'our platform translates American Sign Language into text and speech '
        '— and vice versa — instantly through your webcam and microphone.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
          height: 1.65,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CTA Button — "Get Started" with arrow icon
  // --------------------------------------------------------------------------
  Widget _buildCtaButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/translate');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textLight,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        elevation: 4,
        shadowColor: const Color(0x1A000000),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }

  // ==========================================================================
  // About Section — "How It Works"
  // Matches: padding 4rem 2rem, text-align center
  // ==========================================================================
  Widget _buildAboutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // Heading — matches #about-heading: 2rem, color textDark
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Step cards — matches #about-steps: flex, gap 2rem, wrap
          // On mobile these stack vertically
          const StepCard(
            icon: Icons.camera_alt_outlined,
            title: 'Sign with Camera',
            description:
                'Use your webcam to perform ASL signs. Our AI watches and '
                'interprets your gestures in real time.',
          ),
          const SizedBox(height: AppSpacing.md),
          const StepCard(
            icon: Icons.psychology_outlined,
            title: 'AI Translates',
            description:
                'Our custom-trained CNN model processes each frame and '
                'identifies the signs with high accuracy.',
          ),
          const SizedBox(height: AppSpacing.md),
          const StepCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Text & Speech Output',
            description:
                'Translated text appears instantly and can be spoken aloud. '
                'You can also type text to generate ASL visuals.',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Footer
  // Matches: text-align center, padding 2rem, color #777, font-size 0.9rem
  // ==========================================================================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: AppColors.bgColor,
      child: const Text(
        '© 2026 ASLive. Developed by Aaryan. Abhinab. Prinshab. Binayak.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF777777),
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}
