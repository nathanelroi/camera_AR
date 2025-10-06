
import 'package:flutter/material.dart';
import '../models/photo_capture.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart';

class ResultPage extends StatefulWidget {
  final PhotoCapture capture;

  const ResultPage({super.key, required this.capture});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late TextEditingController notesController;
  String? calculationResult;
  bool isCalculating = false;
  bool hasCalculated = false;

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController(text: widget.capture.notes ?? '');
    _performCalculations();
  }

  Future<void> _performCalculations() async {
    setState(() {
      isCalculating = true;
    });

    try {
      final result = await CalculationService.performMeasurements(widget.capture);
      setState(() {
        calculationResult = result;
        hasCalculated = true;
      });
    } catch (e) {
      setState(() {
        calculationResult = 'Error performing calculations: $e';
        hasCalculated = true;
      });
    } finally {
      setState(() {
        isCalculating = false;
      });
    }
  }

  Future<void> _saveResults() async {
    final updatedCapture = widget.capture.copyWith(
      calculationResult: calculationResult,
      notes: notesController.text.isEmpty ? null : notesController.text,
    );

    await StorageService.savePhotoCapture(updatedCapture);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Results'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _saveResults,
            icon: const Icon(Icons.save),
            tooltip: 'Save Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos Section
            const Text(
              'Captured Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Front Photo
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Front View',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.capture.frontPhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  widget.capture.frontPhoto!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Profile Photo
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Profile View',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.capture.profilePhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  widget.capture.profilePhoto!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Calculations Section
            const Text(
              'Measurement Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: isCalculating
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Performing calculations...'),
                      ],
                    )
                  : hasCalculated
                      ? Text(
                          calculationResult ?? 'No results available',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        )
                      : const Text(
                          'Calculations will appear here...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
            ),
            
            const SizedBox(height: 32),
            
            // Notes Section
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Add your notes, observations, or comments here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Capture Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capture Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captured: ${widget.capture.captureTime.toLocal().toString().split('.')[0]}',
                  ),
                  if (widget.capture.frontPhoto != null)
                    Text('Front Photo: ${_getFileName(widget.capture.frontPhoto!.path)}'),
                  if (widget.capture.profilePhoto != null)
                    Text('Profile Photo: ${_getFileName(widget.capture.profilePhoto!.path)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
}