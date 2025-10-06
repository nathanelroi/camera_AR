import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_capture.dart';

class StorageService {
  static const String _photoCapturesKey = 'photo_captures';

  static Future<Directory> get _appDocumentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<File> saveImageToStorage(String imagePath, String fileName) async {
    final appDir = await _appDocumentsDirectory;
    final savedImagePath = '${appDir.path}/camera_measure/$fileName';
    
    // Create directory if it doesn't exist
    final directory = Directory('${appDir.path}/camera_measure');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final originalFile = File(imagePath);
    final savedFile = await originalFile.copy(savedImagePath);
    return savedFile;
  }

  static Future<void> savePhotoCapture(PhotoCapture capture) async {
    final prefs = await SharedPreferences.getInstance();
    final captures = await getPhotoCaptureIds();
    final captureId = DateTime.now().millisecondsSinceEpoch.toString();
    captures.add(captureId);
    
    await prefs.setStringList(_photoCapturesKey, captures);
    await prefs.setString('${captureId}_capture_time', capture.captureTime.toIso8601String());
    
    if (capture.frontPhoto != null) {
      await prefs.setString('${captureId}_front_photo', capture.frontPhoto!.path);
    }
    if (capture.profilePhoto != null) {
      await prefs.setString('${captureId}_profile_photo', capture.profilePhoto!.path);
    }
    if (capture.calculationResult != null) {
      await prefs.setString('${captureId}_calculation', capture.calculationResult!);
    }
    if (capture.notes != null) {
      await prefs.setString('${captureId}_notes', capture.notes!);
    }
  }

  static Future<List<String>> getPhotoCaptureIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_photoCapturesKey) ?? [];
  }

  static Future<PhotoCapture?> getPhotoCapture(String captureId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final captureTimeString = prefs.getString('${captureId}_capture_time');
    if (captureTimeString == null) return null;
    
    final captureTime = DateTime.parse(captureTimeString);
    final frontPhotoPath = prefs.getString('${captureId}_front_photo');
    final profilePhotoPath = prefs.getString('${captureId}_profile_photo');
    final calculation = prefs.getString('${captureId}_calculation');
    final notes = prefs.getString('${captureId}_notes');
    
    return PhotoCapture(
      captureTime: captureTime,
      frontPhoto: frontPhotoPath != null ? File(frontPhotoPath) : null,
      profilePhoto: profilePhotoPath != null ? File(profilePhotoPath) : null,
      calculationResult: calculation,
      notes: notes,
    );
  }

  static Future<List<PhotoCapture>> getAllPhotoCaptures() async {
    final captureIds = await getPhotoCaptureIds();
    final captures = <PhotoCapture>[];
    
    for (final id in captureIds) {
      final capture = await getPhotoCapture(id);
      if (capture != null) {
        captures.add(capture);
      }
    }
    
    return captures;
  }
}