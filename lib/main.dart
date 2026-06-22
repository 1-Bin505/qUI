// lib/main.dart
//
// SignSpeak — ASL to Text
// Wires the ML backend pipeline into the homepage UI.
// Run with: flutter run -d android

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'utils/model_inspector.dart';
import 'services/asl_pipeline.dart';
import 'services/inference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── STEP 1: Run this ONCE to verify your model's tensor shapes ──
  // Comment out after you've read the printed output and updated constants.dart
  await ModelInspector.inspect();

  runApp(const SignSpeakApp());
}

class SignSpeakApp extends StatelessWidget {
  const SignSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignSpeak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ASLPipeline _pipeline = ASLPipeline();

  bool _isInitializing = true;
  bool _isRunning = false;
  String _detectedText = 'Your signs will appear here...';
  double _confidence = 0.0;
  double _bufferProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPipeline();
  }

  Future<void> _initPipeline() async {
    try {
      await _pipeline.initialize();

      _pipeline.onResult = (InferenceResult result) {
        if (mounted) {
          setState(() {
            _detectedText = result.label;
            _confidence = result.confidence;
          });
        }
      };

      _pipeline.onError = (String error) {
        if (mounted) {
          setState(() => _errorMessage = error);
        }
      };

      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Init failed: $e';
      });
    }
  }

  void _togglePipeline() {
    if (_isRunning) {
      _pipeline.stop();
      setState(() {
        _isRunning = false;
        _bufferProgress = 0.0;
      });
    } else {
      _pipeline.start();
      setState(() => _isRunning = true);
      // Poll buffer progress for UI
      _pollBufferProgress();
    }
  }

  void _pollBufferProgress() async {
    while (_isRunning && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _bufferProgress = _pipeline.bufferProgress);
      }
    }
  }

  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.sign_language, color: Color(0xFF7986CB)),
            SizedBox(width: 10),
            Text(
              'SignSpeak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Hero Text
            const Text(
              'ASL to Text,\nInstantly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'CNN-powered sign language recognition\nusing 30-frame video analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 36),

            // Camera Feed
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5C6BC0), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _buildCameraPreview(),
              ),
            ),

            // Buffer progress bar
            if (_isRunning) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _bufferProgress,
                backgroundColor: Colors.white12,
                color: const Color(0xFF7986CB),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                'Buffering frames: ${(_bufferProgress * 30).toInt()}/30',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],

            const SizedBox(height: 20),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),

            // Start / Stop Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isInitializing ? null : _togglePipeline,
                icon: _isInitializing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 26,
                      ),
                label: Text(
                  _isInitializing
                      ? 'Initializing...'
                      : _isRunning
                          ? 'Stop'
                          : 'Start Signing',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning
                      ? Colors.redAccent.shade700
                      : const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detected Text Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_fields,
                              color: Color(0xFF7986CB), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'DETECTED TEXT',
                            style: TextStyle(
                              color: Color(0xFF7986CB),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (_confidence > 0)
                        Text(
                          '${(_confidence * 100).toStringAsFixed(0)}% conf.',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _detectedText,
                    style: TextStyle(
                      color: _detectedText == 'Your signs will appear here...'
                          ? Colors.white30
                          : Colors.white,
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Feature Cards
            Row(
              children: [
                _featureCard(Icons.video_library, '30-Frame\nAnalysis'),
                const SizedBox(width: 12),
                _featureCard(Icons.bolt, 'Real-Time\nDetection'),
                const SizedBox(width: 12),
                _featureCard(Icons.memory, 'CNN\nPowered'),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _pipeline.cameraController;

    if (_isInitializing || controller == null || !controller.value.isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 60,
            color: _isInitializing ? const Color(0xFF7986CB) : Colors.white30,
          ),
          const SizedBox(height: 12),
          Text(
            _isInitializing ? 'Initializing camera...' : 'Camera Feed',
            style: TextStyle(
              color: _isInitializing ? Colors.white70 : Colors.white30,
              fontSize: 16,
            ),
          ),
          if (_isInitializing) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Color(0xFF7986CB)),
            ),
          ]
        ],
      );
    }

    return CameraPreview(controller);
  }

  Widget _featureCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7986CB), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}