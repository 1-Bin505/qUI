// lib/main.dart
//
// ASLive — Real-Time ASL Translation (Flutter)
// ==============================================
// Ported from the Flask web app (app1.py + templates/ + static/).
//
// Architecture:
//   main.dart               → App entry, routing, theme
//   theme/app_theme.dart    → Design tokens from CSS :root variables
//   screens/landing_screen  → Port of index.html (hero + how-it-works)
//   screens/translate_screen→ Port of translate.html (ASL→Text + Text→ASL)
//   widgets/                → Reusable components (hand_sign_card, step_card, etc.)
//   services/               → Existing ML pipeline (asl_pipeline, inference_service)
//   utils/                  → Existing model inspector
//
// Run with:
//   flutter run -d android
//   flutter run -d ios
//
// Required packages (pubspec.yaml):
//   - camera
//   - tflite_flutter (or equivalent, from existing pipeline)
//   - google_fonts (optional — can embed Outfit font instead)
//
// NOTE: The sign images (sign_a.png … sign_v.png) must be copied to
//       assets/images/ in the Flutter project and declared in pubspec.yaml.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/translate_screen.dart';
// import 'utils/model_inspector.dart';
// import 'services/asl_pipeline.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for consistent mobile layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style to match the warm light theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // ── Model inspection (uncomment once to verify tensor shapes) ──
  // await ModelInspector.inspect();

  runApp(const ASLiveApp());
}

class ASLiveApp extends StatelessWidget {
  const ASLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASLive — ASL to Text/Speech Translator',
      debugShowCheckedModeBanner: false,

      // Theme uses the design tokens ported from static/css/style.css
      theme: buildAppTheme(),

      // Routes mirror the Flask @app.route('/') and @app.route('/translate')
      initialRoute: '/',
      routes: {
        '/': (_) => const LandingScreen(),
        '/translate': (_) => const TranslateScreen(),
      },
    );
  }
}
