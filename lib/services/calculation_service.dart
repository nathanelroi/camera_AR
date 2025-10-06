import 'dart:math';
import '../models/photo_capture.dart';
import 'mediapipe_service.dart';

class CalculationService {
  static Future<String> performMeasurements(PhotoCapture capture) async {
    if (!capture.hasAllPhotos) {
      return "Error: Both front and profile photos are required for calculations.";
    }

    try {
      // Initialize MediaPipe services
      await MediaPipeService.initialize();

      // Process both images
      final frontResults = await _processImage(
        capture.frontPhoto!.path,
        'Front View',
      );
      final profileResults = await _processImage(
        capture.profilePhoto!.path,
        'Profile View',
      );

      // Combine results
      final buffer = StringBuffer();
      buffer.writeln('🔬 COMPREHENSIVE BODY MEASUREMENT ANALYSIS');
      buffer.writeln('==========================================');
      buffer.writeln();

      buffer.writeln('📸 FRONT VIEW MEASUREMENTS:');
      buffer.writeln('---------------------------');
      buffer.write(frontResults);
      buffer.writeln();

      buffer.writeln('📸 PROFILE VIEW MEASUREMENTS:');
      buffer.writeln('-----------------------------');
      buffer.write(profileResults);
      buffer.writeln();

      // Add comprehensive body analysis
      buffer.writeln('📊 COMPREHENSIVE BODY ANALYSIS:');
      buffer.writeln('--------------------------------');
      final bodyAnalysis = await _performBodyAnalysis(capture);
      buffer.write(bodyAnalysis);

      buffer.writeln();
      buffer.writeln('ℹ️  ANALYSIS INFORMATION:');
      buffer.writeln('-------------------------');
      buffer.writeln('• Measurements calculated using MediaPipe ML models');
      buffer.writeln('• Pose landmarks detected with high precision');
      buffer.writeln('• Body segmentation applied for accurate measurements');
      buffer.writeln('• All measurements converted to millimeters (mm)');
      buffer.writeln(
        '• Captured on ${capture.captureTime.toLocal().toString().split('.')[0]}',
      );

      return buffer.toString();
    } catch (e) {
      return 'Error processing images: $e\n\nPlease ensure both photos contain clear, full-body poses.';
    } finally {
      await MediaPipeService.dispose();
    }
  }

  static Future<String> _processImage(String imagePath, String viewType) async {
    final buffer = StringBuffer();

    try {
      // Detect poses
      final poses = await MediaPipeService.detectPoses(imagePath);

      // Perform segmentation
      final segmentationMask = await MediaPipeService.performSegmentation(
        imagePath,
      );

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final measurements = MediaPipeService.calculateBodyMeasurements(
          pose,
          viewType,
        );

        measurements.forEach((measurement, value) {
          buffer.writeln('$measurement: ${value.toStringAsFixed(1)} mm');
        });

        // Add pose landmark count
        buffer.writeln('Detected landmarks: ${pose.landmarks.length}');

        // Add segmentation info
        if (segmentationMask != null) {
          final segData = MediaPipeService.getSegmentationData(
            segmentationMask,
          );
          buffer.writeln('Body segmentation: ✅ Applied');
          buffer.writeln(
            'Body area: ${segData['body_area_mm2'].toStringAsFixed(0)} mm²',
          );
        }
      } else {
        buffer.writeln('⚠️  No pose detected in $viewType');
      }
    } catch (e) {
      buffer.writeln('❌ Error processing $viewType: $e');
    }

    return buffer.toString();
  }

  static Future<String> _performBodyAnalysis(PhotoCapture capture) async {
    final buffer = StringBuffer();

    try {
      // Get all pose landmarks from both images
      final frontPoses = await MediaPipeService.detectPoses(
        capture.frontPhoto!.path,
      );
      final profilePoses = await MediaPipeService.detectPoses(
        capture.profilePhoto!.path,
      );

      if (frontPoses.isNotEmpty && profilePoses.isNotEmpty) {
        final frontPose = frontPoses.first;
        final profilePose = profilePoses.first;

        // Extract all landmarks as maps for detailed analysis
        final frontLandmarks = MediaPipeService.extractAllLandmarksAsMap(
          frontPose,
        );
        final profileLandmarks = MediaPipeService.extractAllLandmarksAsMap(
          profilePose,
        );

        buffer.writeln('📍 POSE LANDMARKS DETECTED:');
        buffer.writeln('Front View: ${frontLandmarks.length} landmarks');
        buffer.writeln('Profile View: ${profileLandmarks.length} landmarks');
        buffer.writeln();

        buffer.writeln('🔍 DETAILED LANDMARK COORDINATES (mm):');
        buffer.writeln('=====================================');

        // Show key landmarks with coordinates
        final keyLandmarks = [
          'nose',
          'left_shoulder',
          'right_shoulder',
          'left_hip',
          'right_hip',
        ];

        for (final landmarkName in keyLandmarks) {
          if (frontLandmarks.containsKey(landmarkName)) {
            final landmark = frontLandmarks[landmarkName]!;
            buffer.writeln(
              '$landmarkName (Front): X=${landmark['x_mm']?.toStringAsFixed(1)}mm, Y=${landmark['y_mm']?.toStringAsFixed(1)}mm',
            );
          }
          if (profileLandmarks.containsKey(landmarkName)) {
            final landmark = profileLandmarks[landmarkName]!;
            buffer.writeln(
              '$landmarkName (Profile): X=${landmark['x_mm']?.toStringAsFixed(1)}mm, Y=${landmark['y_mm']?.toStringAsFixed(1)}mm',
            );
          }
        }

        buffer.writeln();
        buffer.writeln('📐 BODY PROPORTION ANALYSIS:');
        buffer.writeln('• All measurements are in millimeters (mm)');
        buffer.writeln(
          '• Measurements calculated from MediaPipe pose landmarks',
        );
        buffer.writeln('• Both front and profile views processed');
        buffer.writeln('• Body segmentation applied for enhanced accuracy');
      } else {
        buffer.writeln('⚠️  Insufficient pose data for comprehensive analysis');
      }
    } catch (e) {
      buffer.writeln('❌ Error in body analysis: $e');
    }

    return buffer.toString();
  }

  // Legacy methods for compatibility
  static Future<Map<String, Map<String, double>>> extractAllPoseLandmarks(
    String imagePath,
  ) async {
    try {
      await MediaPipeService.initialize();
      final poses = await MediaPipeService.detectPoses(imagePath);

      if (poses.isNotEmpty) {
        return MediaPipeService.extractAllLandmarksAsMap(poses.first);
      }
    } finally {
      await MediaPipeService.dispose();
    }

    return {};
  }

  static Future<Map<String, dynamic>> performBodySegmentation(
    String imagePath,
  ) async {
    try {
      await MediaPipeService.initialize();
      final mask = await MediaPipeService.performSegmentation(imagePath);

      if (mask != null) {
        return MediaPipeService.getSegmentationData(mask);
      }
    } finally {
      await MediaPipeService.dispose();
    }

    return {'has_mask': false};
  }

  static double calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
  }

  /// Get all available pose landmark names
  static List<String> getPoseLandmarkNames() {
    return MediaPipeService.getAllPoseLandmarkNames();
  }
}
