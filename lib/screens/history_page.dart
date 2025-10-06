import 'package:flutter/material.dart';
import '../models/photo_capture.dart';
import '../services/storage_service.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<PhotoCapture> captures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    final loadedCaptures = await StorageService.getAllPhotoCaptures();
    setState(() {
      captures = loadedCaptures.reversed.toList(); // Show newest first
      isLoading = false;
    });
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
        title: const Text('Measurement History'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : captures.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No measurements yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start capturing face measurements to see them here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: captures.length,
                  itemBuilder: (context, index) {
                    final capture = captures[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: capture.frontPhoto != null
                              ? ClipOval(
                                  child: Image.file(
                                    capture.frontPhoto!,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  ),
                                )
                              : const Icon(
                                  Icons.face,
                                  color: Colors.white,
                                ),
                        ),
                        title: Text(
                          'Measurement ${captures.length - index}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capture.captureTime.toLocal().toString().split('.')[0],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (capture.frontPhoto != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Front',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                if (capture.frontPhoto != null && capture.profilePhoto != null)
                                  const SizedBox(width: 4),
                                if (capture.profilePhoto != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Profile',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _viewCapture(capture),
                      ),
                    );
                  },
                ),
    );
  }
}