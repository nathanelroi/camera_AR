import 'package:flutter/material.dart';
import '../services/arcore_service.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  bool _isCalibrating = false;
  double _currentRatio = ARCoreService.pixelsToMmRatio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCore Calibration'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.view_in_ar,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Measurement Calibration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                ARCoreService.isCalibrated 
                    ? 'Current calibration: ${_currentRatio.toStringAsFixed(6)} pixels/mm'
                    : 'Your device needs to be calibrated for accurate measurements',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Calibration uses ARCore to determine the exact pixels to millimeters ratio for your device, which ensures accurate measurements.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isCalibrating)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _startCalibration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    ARCoreService.isCalibrated ? 'Recalibrate' : 'Start Calibration',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue Without Calibration'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startCalibration() async {
    setState(() {
      _isCalibrating = true;
    });

    try {
      final ratio = await ARCoreService.calibratePixelsToMmRatio(context);
      setState(() {
        _currentRatio = ratio;
        _isCalibrating = false;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Calibration successful: ${ratio.toStringAsFixed(6)} pixels/mm',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCalibrating = false;
      });

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calibration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}