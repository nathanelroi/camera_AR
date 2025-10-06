import 'dart:io';

class PhotoCapture {
  final File? frontPhoto;
  final File? profilePhoto;
  final DateTime captureTime;
  final String? calculationResult;
  final String? notes;

  PhotoCapture({
    this.frontPhoto,
    this.profilePhoto,
    required this.captureTime,
    this.calculationResult,
    this.notes,
  });

  bool get hasAllPhotos => frontPhoto != null && profilePhoto != null;

  PhotoCapture copyWith({
    File? frontPhoto,
    File? profilePhoto,
    DateTime? captureTime,
    String? calculationResult,
    String? notes,
  }) {
    return PhotoCapture(
      frontPhoto: frontPhoto ?? this.frontPhoto,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      captureTime: captureTime ?? this.captureTime,
      calculationResult: calculationResult ?? this.calculationResult,
      notes: notes ?? this.notes,
    );
  }
}