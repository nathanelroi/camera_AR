import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARCoreService {
  // Default value used when ARCore calibration is not available
  static const double DEFAULT_PIXELS_TO_MM_RATIO = 0.264583; // 96 DPI approximation
  
  // The real-world measurement of our reference object in mm
  static const double REFERENCE_OBJECT_SIZE_MM = 100.0; // 10cm reference object
  
  static double _calculatedPixelsToMmRatio = DEFAULT_PIXELS_TO_MM_RATIO;
  static bool _isCalibrated = false;
  
  /// Returns the current pixels to mm ratio
  static double get pixelsToMmRatio => _calculatedPixelsToMmRatio;
  
  /// Returns whether the service has been calibrated with ARCore
  static bool get isCalibrated => _isCalibrated;
  
  /// Calibrates the pixels to mm ratio using ARCore depth information
  /// Returns the calibrated ratio
  static Future<double> calibratePixelsToMmRatio(BuildContext context) async {
    try {
      // Store the context state
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Check if ARCore is available
      bool isARCoreAvailable = await ArCoreController.checkArCoreAvailability();
      if (!isARCoreAvailable) {
        debugPrint('ARCore is not available on this device');
        // Use the stored messenger to avoid using context after async
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('ARCore is not available on this device. Using default calibration.'),
            duration: Duration(seconds: 3),
          ),
        );
        return DEFAULT_PIXELS_TO_MM_RATIO;
      }

      // ARCore is available, continue with calibration
      final result = await _showCalibrationDialog(context);
      
      return result ? _calculatedPixelsToMmRatio : DEFAULT_PIXELS_TO_MM_RATIO;
    } catch (e) {
      debugPrint('Error during ARCore calibration: $e');
      return DEFAULT_PIXELS_TO_MM_RATIO;
    }
  }
  
  /// Shows the calibration dialog with ARCore
  /// Returns true if calibration was successful, false otherwise
  static Future<bool> _showCalibrationDialog(BuildContext context) async {
    bool calibrationSuccess = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'ARCore Calibration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Please point your camera at a flat surface with the reference object (10cm).',
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 300,
              padding: const EdgeInsets.all(8.0),
              child: _ARCoreCalibrationView(
                onCalibrationComplete: (ratio) {
                  _calculatedPixelsToMmRatio = ratio;
                  _isCalibrated = true;
                  calibrationSuccess = true;
                  Navigator.of(context).pop();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                calibrationSuccess = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    
    return calibrationSuccess;
  }
}

/// Widget that displays ARCore for calibration
class _ARCoreCalibrationView extends StatefulWidget {
  final Function(double) onCalibrationComplete;

  const _ARCoreCalibrationView({required this.onCalibrationComplete});

  @override
  _ARCoreCalibrationViewState createState() => _ARCoreCalibrationViewState();
}

class _ARCoreCalibrationViewState extends State<_ARCoreCalibrationView> {
  ArCoreController? arCoreController;
  bool hasPlacedReferenceObject = false;

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableTapRecognizer: true,
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: hasPlacedReferenceObject ? _calculateRatio : null,
              child: const Text('Calculate Ratio'),
            ),
          ),
        ),
      ],
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    controller.onPlaneTap = _handlePlaneTap;
  }

  void _handlePlaneTap(List<ArCoreHitTestResult> hits) {
    if (hasPlacedReferenceObject) return;
    
    final hit = hits.first;
    _addReferenceObject(hit.pose.translation);
  }

  void _addReferenceObject(vector.Vector3 position) {
    if (arCoreController == null) return;

    final material = ArCoreMaterial(
      color: Color.fromARGB(255, 0, 0, 255), // Blue color
      reflectance: 1.0,
    );
    
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.05, // 5cm radius = 10cm diameter reference object
    );
    
    final node = ArCoreNode(
      shape: sphere,
      position: position,
    );
    
    arCoreController!.addArCoreNode(node);
    
    setState(() {
      hasPlacedReferenceObject = true;
    });
  }

  void _calculateRatio() {
    if (arCoreController == null) return;
    
    // In a real implementation, we would use depth data to calculate
    // the actual pixel to mm ratio. For this example, we're using
    // a simulated approach.
    
    // Get screen metrics
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width * pixelRatio;
    
    // Our reference object is 100mm, estimate how many pixels it would occupy
    // This is a simplified calculation for demonstration
    final estimatedPixels = screenWidth / 3; // Assume reference object takes ~1/3 of screen
    
    // Calculate pixels to mm ratio
    final calculatedRatio = estimatedPixels / ARCoreService.REFERENCE_OBJECT_SIZE_MM;
    
    widget.onCalibrationComplete(calculatedRatio);
  }
}