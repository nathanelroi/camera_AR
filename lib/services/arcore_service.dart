import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ARCoreService {
  // Default value used when calibration is not available
  static const double defaultPixelsToMmRatio = 0.264583; // 96 DPI approximation
  
  // The real-world measurement of our reference object in mm
  static const double referenceObjectSizeMm = 100.0; // 10cm reference object
  
  // Storage keys
  static const String _calibrationKey = 'pixels_to_mm_ratio';
  static const String _calibratedKey = 'is_calibrated';
  
  static double _calculatedPixelsToMmRatio = defaultPixelsToMmRatio;
  static bool _isCalibrated = false;
  
  /// Initialize the service by loading saved calibration
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _calculatedPixelsToMmRatio = prefs.getDouble(_calibrationKey) ?? defaultPixelsToMmRatio;
    _isCalibrated = prefs.getBool(_calibratedKey) ?? false;
  }
  
  /// Returns the current pixels to mm ratio
  static double get pixelsToMmRatio => _calculatedPixelsToMmRatio;
  
  /// Returns whether the service has been calibrated
  static bool get isCalibrated => _isCalibrated;
  
  /// Reset calibration to default values
  static Future<void> resetCalibration() async {
    _calculatedPixelsToMmRatio = defaultPixelsToMmRatio;
    _isCalibrated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calibrationKey);
    await prefs.remove(_calibratedKey);
  }
  
  /// Calibrates the pixels to mm ratio using manual measurement
  /// Returns the calibrated ratio
  static Future<double> calibratePixelsToMmRatio(BuildContext context) async {
    try {
      // Show manual calibration dialog
      final result = await _showManualCalibrationDialog(context);
      
      if (result != null) {
        _calculatedPixelsToMmRatio = result;
        _isCalibrated = true;
        
        // Save calibration to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_calibrationKey, result);
        await prefs.setBool(_calibratedKey, true);
        
        return result;
      }
      
      return _calculatedPixelsToMmRatio;
    } catch (e) {
      debugPrint('Error during calibration: $e');
      return defaultPixelsToMmRatio;
    }
  }
  
  /// Shows manual calibration dialog
  static Future<double?> _showManualCalibrationDialog(BuildContext context) async {
    double? calibratedRatio;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ManualCalibrationDialog(
          onCalibrationComplete: (ratio) {
            calibratedRatio = ratio;
          },
        );
      },
    );
    
    return calibratedRatio;
  }
}

/// Manual calibration dialog widget
class ManualCalibrationDialog extends StatefulWidget {
  final Function(double) onCalibrationComplete;
  
  const ManualCalibrationDialog({
    super.key,
    required this.onCalibrationComplete,
  });
  
  @override
  State<ManualCalibrationDialog> createState() => _ManualCalibrationDialogState();
}

class _ManualCalibrationDialogState extends State<ManualCalibrationDialog> {
  final TextEditingController _pixelsController = TextEditingController();
  final TextEditingController _mmController = TextEditingController();
  bool _isValid = false;
  
  @override
  void dispose() {
    _pixelsController.dispose();
    _mmController.dispose();
    super.dispose();
  }
  
  void _validateInputs() {
    final pixels = double.tryParse(_pixelsController.text);
    final mm = double.tryParse(_mmController.text);
    
    setState(() {
      _isValid = pixels != null && mm != null && pixels > 0 && mm > 0;
    });
  }
  
  void _performCalibration() {
    final pixels = double.parse(_pixelsController.text);
    final mm = double.parse(_mmController.text);
    
    final ratio = pixels / mm;
    widget.onCalibrationComplete(ratio);
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Calibration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'To calibrate your device for accurate measurements, you need a reference object with a known size.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Instructions:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Place a ruler or any object with known length on the screen\n'
            '2. Measure how many pixels it covers on your screen\n'
            '3. Enter the pixel count and real-world measurement below',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pixelsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pixels',
              hintText: 'e.g., 378',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _validateInputs(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mmController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Millimeters (mm)',
              hintText: 'e.g., 100',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _validateInputs(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Example: If a 10cm ruler appears as 378 pixels on your screen, enter "378" pixels and "100" mm.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? _performCalibration : null,
          child: const Text('Calibrate'),
        ),
      ],
    );
  }
}