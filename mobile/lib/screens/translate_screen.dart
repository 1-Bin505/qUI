// lib/screens/translate_screen.dart
//
// ASLive — Translate Screen
// ===========================
// Flutter port of templates/translate.html + inline <style> + static/css/style.css.
//
// Layout hierarchy (matches HTML):
//   body.translate-page
//   ├─ nav#translate-nav            ← AppBar with logo + mode tabs
//   └─ main#translate-main
//      ├─ section#mode-asl-to-text  ← Camera panel + Output panel + Controls
//      └─ section#mode-text-to-asl  ← Text input + ASL sign output + Controls
//
// CSS mapping:
//   #translate-nav    → AppBar, bg darkBrown, sticky
//   #mode-tabs        → Row of ModeTab widgets
//   .translate-split  → Column on mobile (matches @media max-width 768px)
//   .panel-camera     → Container, bg cardBrown, text textLight
//   .panel-output     → Container, bg cardLightTan, text textDark
//   .video-wrapper    → aspect-ratio 4/3, bg #111, radius 12
//   #prediction-overlay → gradient overlay at bottom of video
//   #transcript-strip → bg rgba(255,255,255,0.05), border, radius 8
//   .controls-bar     → Row of ControlButton widgets
//   .panel-input      → textarea equivalent
//   .panel-asl-output → ASL sign cards display
//
// The camera/inference pipeline is wired via the existing ASLPipeline service.
// This screen is purely UI — it calls pipeline.start(), pipeline.stop(), etc.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../widgets/mode_tab.dart';
import '../widgets/control_button.dart';
import '../services/asl_pipeline.dart';
import '../services/inference_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  // ── Mode switching (matches tab-asl-to-text / tab-text-to-asl) ──
  int _activeMode = 0; // 0 = ASL→Text, 1 = Text→ASL

  // ── ASL → Text state ──
  final ASLPipeline _pipeline = ASLPipeline();
  bool _isInitializing = true;
  bool _isCameraRunning = false;
  String _predictionWord = '—';
  double _confidence = 0.0;
  double _bufferProgress = 0.0;
  String _transcriptText = '';
  String _translatedOutput = '';
  String? _errorMessage;

  // ── Text → ASL state ──
  final TextEditingController _textInputController = TextEditingController();
  List<Map<String, String?>> _aslSigns = [];
  bool _showAslPlaceholder = true;

  @override
  void initState() {
    super.initState();
    _initPipeline();
  }

  Future<void> _initPipeline() async {
    try {
      await _pipeline.initialize();

      _pipeline.onResult = (InferenceResult result) {
        if (!mounted) return;
        setState(() {
          _predictionWord = result.label.toUpperCase();
          _confidence = result.confidence;

          // Append to transcript (mirrors JS logic for is_new)
          if (_transcriptText.isEmpty ||
              !_transcriptText.trimRight().endsWith(result.label)) {
            _transcriptText += '${result.label} ';
            _translatedOutput = _transcriptText;
          }
        });
      };

      _pipeline.onError = (String error) {
        if (mounted) setState(() => _errorMessage = error);
      };

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Init failed: $e';
        });
      }
    }
  }

  void _toggleCamera() {
    if (_isCameraRunning) {
      _pipeline.stop();
      setState(() {
        _isCameraRunning = false;
        _bufferProgress = 0.0;
      });
    } else {
      _pipeline.start();
      setState(() => _isCameraRunning = true);
      _pollBuffer();
    }
  }

  void _pollBuffer() async {
    while (_isCameraRunning && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _bufferProgress = _pipeline.bufferProgress);
      }
    }
  }

  void _clearOutput() {
    setState(() {
      _transcriptText = '';
      _translatedOutput = '';
      _predictionWord = '—';
      _confidence = 0.0;
    });
  }

  void _resetBuffer() {
    setState(() => _bufferProgress = 0.0);
    // Pipeline reset handled internally
  }

  // ── Text → ASL helpers ──
  void _translateTextToAsl() {
    final text = _textInputController.text.trim();
    if (text.isEmpty) return;

    final signs = <Map<String, String?>>[];
    for (final char in text.toUpperCase().split('')) {
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        signs.add({
          'letter': char,
          'image': 'assets/images/sign_${char.toLowerCase()}.png',
        });
      } else if (char == ' ') {
        signs.add({'letter': ' ', 'image': null});
      }
    }
    setState(() {
      _aslSigns = signs;
      _showAslPlaceholder = false;
    });
  }

  void _clearTextInput() {
    _textInputController.clear();
    setState(() {
      _aslSigns = [];
      _showAslPlaceholder = true;
    });
  }

  @override
  void dispose() {
    _pipeline.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      // ── NAV BAR ── matches #translate-nav
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ASLive',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textLight,
          ),
        ),
        actions: [
          // Mode tabs — matches #mode-tabs
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              children: [
                ModeTab(
                  icon: Icons.camera_alt_outlined,
                  label: 'ASL→Text',
                  isActive: _activeMode == 0,
                  onTap: () => setState(() => _activeMode = 0),
                ),
                const SizedBox(width: AppSpacing.xs),
                ModeTab(
                  icon: Icons.chat_bubble_outline,
                  label: 'Text→ASL',
                  isActive: _activeMode == 1,
                  onTap: () => setState(() => _activeMode = 1),
                ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _activeMode == 0
            ? _buildAslToTextMode()
            : _buildTextToAslMode(),
      ),
    );
  }

  // ==========================================================================
  // MODE 1: ASL → Text
  // Matches section#mode-asl-to-text
  // ==========================================================================
  Widget _buildAslToTextMode() {
    return SingleChildScrollView(
      key: const ValueKey('asl-to-text'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // ── Camera Panel ── matches .panel.panel-camera
          _buildCameraPanel(),
          const SizedBox(height: AppSpacing.md),

          // ── Output Panel ── matches .panel.panel-output
          _buildOutputPanel(),
          const SizedBox(height: AppSpacing.md),

          // ── Error message ──
          if (_errorMessage != null) _buildErrorBanner(),

          // ── Controls Bar ── matches .controls-bar#asl-controls
          _buildAslControlsBar(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Camera Panel
  // Matches: .panel-camera (bg cardBrown), .video-wrapper (4:3, bg #111)
  // --------------------------------------------------------------------------
  Widget _buildCameraPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBrown,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel header — matches .panel-header
          _buildPanelHeader(
            label: 'Camera Feed',
            trailing: _buildStatusDot(),
          ),

          // Video wrapper — matches .video-wrapper: aspect-ratio 4/3, bg #111
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Camera preview or placeholder
                  _buildCameraPreview(),

                  // Prediction overlay — matches #prediction-overlay
                  if (_isCameraRunning) _buildPredictionOverlay(),
                ],
              ),
            ),
          ),

          // Transcript strip — matches #transcript-strip
          _buildTranscriptStrip(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _pipeline.cameraController;

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      // Placeholder — matches #video-placeholder
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 56,
              color: _isInitializing
                  ? AppColors.secondaryTan
                  : const Color(0xFF666666),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isInitializing
                  ? 'Initializing camera...'
                  : 'Click Start Camera below',
              style: TextStyle(
                color: _isInitializing
                    ? AppColors.textLight
                    : const Color(0xFF666666),
                fontSize: 14,
                fontFamily: 'Outfit',
              ),
            ),
            if (_isInitializing) ...[
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryTan,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return CameraPreview(controller);
  }

  // Prediction overlay — gradient bottom, word + confidence bar
  // Matches #prediction-overlay styling from translate.html <style>
  Widget _buildPredictionOverlay() {
    final bool hasWord = _predictionWord != '—' && _predictionWord != '…';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.overlayBlack],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prediction word — matches #prediction-word
            Text(
              _predictionWord,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: hasWord ? AppColors.accentGreen : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            // Confidence row — matches #confidence-row
            Row(
              children: [
                // Buffer bar — matches #buffer-bar-wrap / #buffer-bar
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _bufferProgress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Confidence % — matches #confidence-pct
                SizedBox(
                  width: 40,
                  child: Text(
                    _confidence > 0
                        ? '${(_confidence * 100).toStringAsFixed(0)}%'
                        : '—',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Transcript strip — matches #transcript-strip
  Widget _buildTranscriptStrip() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      constraints: const BoxConstraints(minHeight: 38),
      child: Text(
        _transcriptText.isEmpty
            ? 'Detected words appear here…'
            : _transcriptText,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          color: _transcriptText.isEmpty
              ? const Color(0xFF555555)
              : AppColors.textLight,
        ),
      ),
    );
  }

  // Status dot — matches .status-dot (green when live)
  Widget _buildStatusDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isCameraRunning ? const Color(0xFF4ADE80) : const Color(0xFF888888),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Output Panel
  // Matches: .panel.panel-output (bg cardLightTan)
  // --------------------------------------------------------------------------
  Widget _buildOutputPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: AppColors.cardLightTan,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(label: 'Translation Output'),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _translatedOutput.isEmpty
                  ? 'Translated text will appear here…'
                  : _translatedOutput,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: _translatedOutput.isEmpty
                    ? const Color(0xFF888888)
                    : AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ASL Controls Bar
  // Matches: .controls-bar#asl-controls — Start Camera, Speak, Clear, Reset
  // --------------------------------------------------------------------------
  Widget _buildAslControlsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: [
          ControlButton(
            icon: _isCameraRunning
                ? Icons.stop_rounded
                : Icons.camera_alt_outlined,
            label: _isCameraRunning ? 'Stop Camera' : 'Start Camera',
            isPrimary: true,
            onPressed: _isInitializing ? null : _toggleCamera,
          ),
          ControlButton(
            icon: Icons.volume_up_rounded,
            label: 'Speak',
            onPressed: () {
              // TTS integration placeholder — mirrors btn-speak-output
            },
          ),
          ControlButton(
            icon: Icons.delete_outline_rounded,
            label: 'Clear',
            onPressed: _clearOutput,
          ),
          ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onPressed: _resetBuffer,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Error banner
  // --------------------------------------------------------------------------
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorCoral.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.errorCoral.withValues(alpha: 0.3)),
      ),
      child: Text(
        _errorMessage ?? '',
        style: const TextStyle(
          color: AppColors.errorCoral,
          fontSize: 13,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  // ==========================================================================
  // MODE 2: Text → ASL
  // Matches section#mode-text-to-asl
  // ==========================================================================
  Widget _buildTextToAslMode() {
    return SingleChildScrollView(
      key: const ValueKey('text-to-asl'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // ── Text Input Panel ── matches .panel.panel-input
          _buildTextInputPanel(),
          const SizedBox(height: AppSpacing.md),

          // ── ASL Output Panel ── matches .panel.panel-asl-output
          _buildAslOutputPanel(),
          const SizedBox(height: AppSpacing.md),

          // ── Controls ──
          _buildTextControlsBar(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Text Input Panel
  // Matches: .panel-input (bg cardLightTan)
  // --------------------------------------------------------------------------
  Widget _buildTextInputPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardLightTan,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with mic button — matches .panel-header with .mic-btn
          _buildPanelHeader(
            label: 'Type or Speak',
            trailing: IconButton(
              icon: const Icon(Icons.mic_none_rounded, size: 22),
              color: AppColors.textDark,
              onPressed: () {
                // Speech recognition placeholder — mirrors btn-mic
              },
            ),
          ),
          // Textarea — matches #text-input
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _textInputController,
              maxLines: 6,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                hintText: 'Type a word or sentence…',
                hintStyle: TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontFamily: 'Outfit',
                  fontSize: 18,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ASL Output Panel
  // Matches: .panel-asl-output (bg cardLightTan)
  // --------------------------------------------------------------------------
  Widget _buildAslOutputPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: AppColors.cardLightTan,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPanelHeader(label: 'ASL Output'),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _showAslPlaceholder
                ? _buildAslPlaceholder()
                : _buildAslSignsGrid(),
          ),
        ],
      ),
    );
  }

  // Placeholder — matches .asl-placeholder (hand icon + text)
  Widget _buildAslPlaceholder() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.sign_language_outlined,
            size: 56,
            color: AppColors.subtleGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ASL signs will appear here',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              color: AppColors.subtleGray.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ASL signs grid — matches .asl-signs-display (flex-wrap, gap 10)
  Widget _buildAslSignsGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _aslSigns.map((sign) {
        if (sign['image'] == null) {
          // Space between words
          return const SizedBox(width: 20);
        }
        // ASL sign card — matches .asl-sign-card
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.textLight,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Image.asset(
                  sign['image']!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.cardLightTan,
                    alignment: Alignment.center,
                    child: Text(
                      sign['letter'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sign['letter'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // Text → ASL Controls Bar
  // Matches: .controls-bar with Translate + Clear buttons
  // --------------------------------------------------------------------------
  Widget _buildTextControlsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ControlButton(
            icon: Icons.translate_rounded,
            label: 'Translate',
            isPrimary: true,
            onPressed: _translateTextToAsl,
          ),
          const SizedBox(width: AppSpacing.md),
          ControlButton(
            icon: Icons.delete_outline_rounded,
            label: 'Clear',
            onPressed: _clearTextInput,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Shared: Panel Header
  // Matches .panel-header: padding 1rem, bg rgba(0,0,0,0.05), flex between
  // ==========================================================================
  Widget _buildPanelHeader({
    required String label,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadii.lg),
          topRight: Radius.circular(AppRadii.lg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
