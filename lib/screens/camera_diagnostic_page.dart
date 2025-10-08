import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraDiagnosticPage extends StatefulWidget {
  const CameraDiagnosticPage({super.key});

  @override
  State<CameraDiagnosticPage> createState() => _CameraDiagnosticPageState();
}

class _CameraDiagnosticPageState extends State<CameraDiagnosticPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  String _status = 'Initializing...';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _status = 'Getting available cameras...';
      });

      _cameras = await availableCameras();
      
      setState(() {
        _status = 'Found ${_cameras!.length} cameras';
      });

      if (_cameras!.isNotEmpty) {
        final camera = _cameras!.first;
        
        setState(() {
          _status = 'Initializing camera: ${camera.name}';
        });

        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();

        setState(() {
          _isLoading = false;
          _status = 'Camera ready!';
        });
      } else {
        setState(() {
          _isLoading = false;
          _status = 'No cameras found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
        _status = 'Error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Status information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_error.isNotEmpty) 
                  Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                if (_controller != null) ...[
                  Text('Initialized: ${_controller!.value.isInitialized}'),
                  Text('Preview Size: ${_controller!.value.previewSize}'),
                  Text('Aspect Ratio: ${_controller!.value.aspectRatio}'),
                ],
                if (_cameras != null) ...[
                  const SizedBox(height: 8),
                  const Text('Available Cameras:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._cameras!.map((camera) => Text('- ${camera.name} (${camera.lensDirection})')),
                ],
              ],
            ),
          ),
          
          // Camera preview
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Loading camera...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    )
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 64),
                              const SizedBox(height: 16),
                              Text('Error: $_error', 
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _error = '';
                                    _isLoading = true;
                                  });
                                  _initCamera();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _controller != null && _controller!.value.isInitialized
                          ? Stack(
                              children: [
                                // Simple camera preview
                                SizedBox.expand(
                                  child: CameraPreview(_controller!),
                                ),
                                // Test overlay
                                const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 50,
                                  ),
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
          
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = '';
                        _isLoading = true;
                      });
                      _initCamera();
                    },
                    child: const Text('Reinitialize Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller?.value.isInitialized == true
                        ? () async {
                            try {
                              final image = await _controller!.takePicture();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Photo saved: ${image.path}')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Photo failed: $e')),
                              );
                            }
                          }
                        : null,
                    child: const Text('Test Photo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}