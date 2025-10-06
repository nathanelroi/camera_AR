import 'package:flutter/material.dart';
import 'screens/ar_camera_page.dart';
import 'screens/result_page.dart';
import 'services/storage_service.dart';
import 'models/photo_capture.dart';

void main() {
  runApp(const CameraMeasureApp());
}

class CameraMeasureApp extends StatelessWidget {
  const CameraMeasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Measure - Face AR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  List<PhotoCapture> savedCaptures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCaptures();
  }

  Future<void> _loadSavedCaptures() async {
    final captures = await StorageService.getAllPhotoCaptures();
    setState(() {
      savedCaptures = captures;
      isLoading = false;
    });
  }

  void _startNewCapture() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ARCameraPage(),
      ),
    ).then((_) => _loadSavedCaptures()); // Refresh when returning
  }

  void _viewCapture(PhotoCapture capture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(capture: capture),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Measure - Face AR'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue, Colors.blue.shade600],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.face_retouching_natural,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Face Measurement with AR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Capture your face from front and profile views for precise measurements',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Action Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startNewCapture,
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: const Text(
                        'Start New Measurement',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                // Saved Captures Section
                if (savedCaptures.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Previous Measurements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: savedCaptures.length,
                      itemBuilder: (context, index) {
                        final capture = savedCaptures[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.face,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              'Measurement ${savedCaptures.length - index}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Captured: ${capture.captureTime.toLocal().toString().split('.')[0]}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _viewCapture(capture),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_front,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No measurements yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your first face measurement',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
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
