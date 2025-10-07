import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_calibration_service.dart';

class AdvancedCalibrationPage extends StatefulWidget {
  const AdvancedCalibrationPage({super.key});

  @override
  State<AdvancedCalibrationPage> createState() =>
      _AdvancedCalibrationPageState();
}

class _AdvancedCalibrationPageState extends State<AdvancedCalibrationPage> {
  CameraController? _cameraController;
  bool _isInitializing = false;
  bool _isCalibrating = false;
  bool _calibrationComplete = false;
  String _statusMessage = 'Initializing camera...';
  Map<String, dynamic>? _calibrationMetrics;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    CameraCalibrationService.initialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    CameraCalibrationService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Initializing camera...';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Prefer back camera for calibration
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitializing = false;
        _statusMessage = 'Camera ready. Tap "Start Calibration" to begin.';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _startCalibration() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCalibrating = true;
      _statusMessage = 'Step 1/3: Analyzing camera parameters...';
    });

    try {
      // Add delay and status updates for better user feedback
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _statusMessage = 'Step 2/3: Reading device sensors...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _statusMessage = 'Step 3/3: Calculating calibration...';
      });

      // Perform advanced camera calibration
      final success = await CameraCalibrationService.performCalibration(
        cameraController: _cameraController!,
        context: context,
      );

      if (success) {
        final metrics = CameraCalibrationService.getCalibrationMetrics();

        setState(() {
          _isCalibrating = false;
          _calibrationComplete = true;
          _calibrationMetrics = metrics;
          _statusMessage = 'Calibration completed successfully!';
        });

        // Show success dialog
        _showCalibrationResults();
      } else {
        throw Exception('Calibration process failed');
      }
    } catch (e) {
      setState(() {
        _isCalibrating = false;
        _statusMessage = 'Calibration failed: $e';
      });

      // Show error dialog
      _showErrorDialog('Calibration failed: $e');
    }
  }

  void _showCalibrationResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your camera has been calibrated for high-precision measurements.',
            ),
            const SizedBox(height: 16),
            if (_calibrationMetrics != null) ...[
              const Text(
                'Calibration Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pixels to MM Ratio: ${_calibrationMetrics!['pixel_to_mm_ratio'].toStringAsFixed(6)}',
              ),
              Text(
                'Focal Length X: ${_calibrationMetrics!['camera_intrinsics']['fx'].toStringAsFixed(2)}',
              ),
              Text(
                'Focal Length Y: ${_calibrationMetrics!['camera_intrinsics']['fy'].toStringAsFixed(2)}',
              ),
              Text('Accuracy: ${_calibrationMetrics!['accuracy_estimate']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: const Text('Continue to Measurement'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibration Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Camera Calibration'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey),
              ),
              child: _isInitializing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _cameraController?.value.isInitialized == true
                  ? Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        // Calibration overlay
                        if (_isCalibrating)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Analyzing camera parameters...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Grid overlay for reference
                        if (!_isCalibrating && !_calibrationComplete)
                          CustomPaint(
                            size: Size.infinite,
                            painter: CalibrationGridPainter(),
                          ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'Camera not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),

          // Instructions and Controls
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _calibrationComplete
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _calibrationComplete
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: _calibrationComplete
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instructions
                  if (!_calibrationComplete && !_isCalibrating) ...[
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Hold your device steady at arm\'s length\n'
                      '2. Point the camera at eye level\n'
                      '3. Ensure good lighting conditions\n'
                      '4. Tap "Start Calibration" when ready',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Skip Calibration'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isInitializing || _isCalibrating
                              ? null
                              : _calibrationComplete
                              ? () => Navigator.of(context).pop()
                              : _startCalibration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _calibrationComplete
                                ? Colors.green
                                : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _calibrationComplete
                                ? 'Continue'
                                : _isCalibrating
                                ? 'Calibrating...'
                                : 'Start Calibration',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for calibration grid overlay
class CalibrationGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw grid lines
    const int gridLines = 8;
    for (int i = 1; i < gridLines; i++) {
      final double x = size.width * i / gridLines;
      final double y = size.height * i / gridLines;

      // Vertical lines
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      // Horizontal lines
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw center crosshair
    final centerPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    const crossSize = 20.0;

    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
