import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/camera_service.dart';

class PlantCameraCard extends StatefulWidget {
  const PlantCameraCard({super.key});

  @override
  State<PlantCameraCard> createState() => _PlantCameraCardState();
}

class _PlantCameraCardState extends State<PlantCameraCard> {
  Uint8List? _imageBytes;
  bool _isCapturing = false;
  String? _errorMessage;

  Future<void> _captureImage() async {
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final image = await CameraService.captureImage();

      if (!mounted) return;

      setState(() {
        _imageBytes = image;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _errorMessage = 'Unable to capture image. Check the camera connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Camera',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Capture an image of your plant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Image area
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 52,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No plant image captured',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Error message
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Capture button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureImage,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isCapturing
                      ? 'Capturing...'
                      : _imageBytes == null
                          ? 'Capture Plant Image'
                          : 'Capture New Image',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}