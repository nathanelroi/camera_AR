import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/photo_capture.dart';
import '../services/storage_service.dart';
import 'result_page.dart';

class ARCameraPage extends StatefulWidget {
  const ARCameraPage({super.key});

  @override
  State<ARCameraPage> createState() => _ARCameraPageState();
}

class _ARCameraPageState extends State<ARCameraPage> {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  PhotoCapture? currentCapture;
  bool isLoadingCamera = true;
  int currentStep = 0; // 0: front face, 1: profile
  bool isUsingBackCamera = true; // Start with back camera

  final List<String> captureSteps = [
    'Position yourself facing the camera directly',
    'Turn your head to show your profile (side view)'
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        // Use back camera (rear camera) if available, otherwise use front camera
        final backCamera = cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras!.first,
          ),
        );

        cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await cameraController!.initialize();
        setState(() {
          isLoadingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      setState(() {
        isLoadingCamera = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await cameraController!.takePicture();
      final savedFile = await StorageService.saveImageToStorage(
        image.path,
        '${currentStep == 0 ? 'front' : 'profile'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      setState(() {
        if (currentStep == 0) {
          // First photo - front view
          currentCapture = PhotoCapture(
            frontPhoto: savedFile,
            captureTime: DateTime.now(),
          );
          currentStep = 1;
        } else {
          // Second photo - profile view
          currentCapture = currentCapture!.copyWith(
            profilePhoto: savedFile,
          );
          _navigateToResults();
        }
      });

      _showCaptureSuccess();
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  void _showCaptureSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentStep == 1 ? 'Front photo captured! Now capture profile view.' : 'Profile photo captured!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToResults() {
    if (currentCapture != null && currentCapture!.hasAllPhotos) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(capture: currentCapture!),
        ),
      );
    }
  }

  void _resetCapture() {
    setState(() {
      currentCapture = null;
      currentStep = 0;
    });
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;

    setState(() {
      isLoadingCamera = true;
    });

    await cameraController?.dispose();

    final newCameraDirection = isUsingBackCamera 
        ? CameraLensDirection.front 
        : CameraLensDirection.back;

    final newCamera = cameras!.firstWhere(
      (camera) => camera.lensDirection == newCameraDirection,
      orElse: () => cameras!.first,
    );

    cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController!.initialize();
      setState(() {
        isUsingBackCamera = !isUsingBackCamera;
        isLoadingCamera = false;
      });
    } catch (e) {
      debugPrint('Camera switch failed: $e');
      setState(() {
        isLoadingCamera = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoadingCamera) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Measure'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Measurement'),
        backgroundColor: Colors.blue,
        actions: [
          if (cameras != null && cameras!.length > 1)
            IconButton(
              onPressed: _switchCamera,
              icon: Icon(isUsingBackCamera ? Icons.camera_front : Icons.camera_rear),
              tooltip: 'Switch Camera',
            ),
          if (currentCapture != null)
            IconButton(
              onPressed: _resetCapture,
              icon: const Icon(Icons.refresh),
              tooltip: 'Start over',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (cameraController != null && cameraController!.value.isInitialized)
            SizedBox.expand(
              child: CameraPreview(cameraController!),
            ),
          
          // Instructions overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${currentStep + 1} of 2',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    captureSteps[currentStep],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      isUsingBackCamera 
                          ? 'Using back camera - tap switch icon to use front camera'
                          : 'Using front camera - tap switch icon to use back camera',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Capture progress indicator
          if (currentCapture?.frontPhoto != null)
            Positioned(
              top: 140,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Front photo captured',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _capturePhoto,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.camera_alt),
        label: Text(currentStep == 0 ? 'Capture Front' : 'Capture Profile'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}