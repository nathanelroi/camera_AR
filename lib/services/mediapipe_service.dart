import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'arcore_service.dart';

class MediaPipeService {
  static double get _pixelsToMmRatio => ARCoreService.isCalibrated 
      ? ARCoreService.pixelsToMmRatio 
      : 0.264583; // Fallback to approximate conversion (96 DPI)
  
  static late PoseDetector _poseDetector;
  static late SelfieSegmenter _segmenter;
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize pose detector with accurate mode
      final poseDetectorOptions = PoseDetectorOptions(
        mode: PoseDetectionMode.single,
      );
      _poseDetector = PoseDetector(options: poseDetectorOptions);
      
      // Initialize selfie segmenter
      _segmenter = SelfieSegmenter(
        mode: SegmenterMode.single,
        enableRawSizeMask: true,
      );
      
      _initialized = true;
    } catch (e) {
      debugPrint('MediaPipe initialization failed: $e');
      rethrow;
    }
  }
  
  static Future<void> dispose() async {
    if (!_initialized) return;
    
    try {
      await _poseDetector.close();
      await _segmenter.close();
      _initialized = false;
    } catch (e) {
      debugPrint('MediaPipe disposal failed: $e');
    }
  }
  
  static Future<List<Pose>> detectPoses(String imagePath) async {
    await initialize();
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _poseDetector.processImage(inputImage);
  }
  
  static Future<SegmentationMask?> performSegmentation(String imagePath) async {
    await initialize();
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _segmenter.processImage(inputImage);
  }
  
  static Map<String, double> calculateBodyMeasurements(Pose pose, String viewType) {
    final landmarks = pose.landmarks;
    final measurements = <String, double>{};
    
    // Define key landmarks for different views
    if (viewType == 'Front View') {
      // Front view specific measurements
      _addMeasurementIfLandmarksExist(
        measurements, 'Shoulder Width', landmarks,
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder
      );
      
      _addMeasurementIfLandmarksExist(
        measurements, 'Hip Width', landmarks,
        PoseLandmarkType.leftHip, PoseLandmarkType.rightHip
      );
      
      _addMeasurementIfLandmarksExist(
        measurements, 'Chest Width', landmarks,
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder
      );
      
    } else if (viewType == 'Profile View') {
      // Profile view specific measurements
      _addMeasurementIfLandmarksExist(
        measurements, 'Torso Depth', landmarks,
        PoseLandmarkType.nose, PoseLandmarkType.leftShoulder
      );
      
      _addMeasurementIfLandmarksExist(
        measurements, 'Head to Hip', landmarks,
        PoseLandmarkType.nose, PoseLandmarkType.leftHip
      );
    }
    
    // Common measurements for both views
    _addMeasurementIfLandmarksExist(
      measurements, 'Total Height', landmarks,
      PoseLandmarkType.nose, PoseLandmarkType.leftAnkle
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Torso Length', landmarks,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Left Upper Arm', landmarks,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Left Forearm', landmarks,
      PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Right Upper Arm', landmarks,
      PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Right Forearm', landmarks,
      PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Left Thigh', landmarks,
      PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Left Calf', landmarks,
      PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Right Thigh', landmarks,
      PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee
    );
    
    _addMeasurementIfLandmarksExist(
      measurements, 'Right Calf', landmarks,
      PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle
    );
    
    return measurements;
  }
  
  static void _addMeasurementIfLandmarksExist(
    Map<String, double> measurements,
    String measurementName,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    PoseLandmarkType landmark1Type,
    PoseLandmarkType landmark2Type,
  ) {
    final landmark1 = landmarks[landmark1Type];
    final landmark2 = landmarks[landmark2Type];
    
    if (landmark1 != null && landmark2 != null) {
      final distance = _calculateDistance(
        landmark1.x, landmark1.y,
        landmark2.x, landmark2.y
      );
      
      // Get the current pixels to mm ratio (may be ARCore calibrated or default)
      final currentRatio = _pixelsToMmRatio;
      debugPrint('Using pixels to mm ratio: $currentRatio (ARCore calibrated: ${ARCoreService.isCalibrated})');
      
      measurements[measurementName] = distance * currentRatio;
    }
  }
  
  static double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
  }
  
  static Map<String, dynamic> getSegmentationData(SegmentationMask mask) {
    final totalPixels = mask.width * mask.height;
    
    // Get the current pixels to mm ratio (may be ARCore calibrated or default)
    final currentRatio = _pixelsToMmRatio;
    
    final bodyAreaMm2 = totalPixels * pow(currentRatio, 2) * 0.6; // Approximate 60% body coverage
    
    return {
      'width': mask.width,
      'height': mask.height,
      'body_area_mm2': bodyAreaMm2,
      'estimated_body_coverage': 0.6,
      'pixels_to_mm_ratio': currentRatio,
      'is_arcore_calibrated': ARCoreService.isCalibrated,
    };
  }
  
  static List<String> getAllPoseLandmarkNames() {
    return [
      'nose', 'left_eye_inner', 'left_eye', 'left_eye_outer',
      'right_eye_inner', 'right_eye', 'right_eye_outer',
      'left_ear', 'right_ear', 'left_mouth', 'right_mouth',
      'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
      'left_wrist', 'right_wrist', 'left_pinky', 'right_pinky',
      'left_index', 'right_index', 'left_thumb', 'right_thumb',
      'left_hip', 'right_hip', 'left_knee', 'right_knee',
      'left_ankle', 'right_ankle', 'left_heel', 'right_heel',
      'left_foot_index', 'right_foot_index'
    ];
  }
  
  static Map<String, Map<String, double>> extractAllLandmarksAsMap(Pose pose) {
    final landmarks = <String, Map<String, double>>{};
    
    // Get the current pixels to mm ratio (may be ARCore calibrated or default)
    final currentRatio = _pixelsToMmRatio;
    
    for (final entry in pose.landmarks.entries) {
      final landmarkType = entry.key;
      final landmark = entry.value;
      
      landmarks[landmarkType.name] = {
        'x_mm': landmark.x * currentRatio,
        'y_mm': landmark.y * currentRatio,
        'z_mm': landmark.z * currentRatio,
        'likelihood': landmark.likelihood,
        'x_px': landmark.x, // Original pixel values
        'y_px': landmark.y, // Original pixel values
        'z_px': landmark.z, // Original pixel values
      };
    }
    
    return landmarks;
  }
}