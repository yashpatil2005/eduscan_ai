import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:eduscan_ai/screens/add_notes/image_preview_screen.dart';

class CustomCameraScreen extends StatefulWidget {
  final List<File> existingImages;
  const CustomCameraScreen({super.key, required this.existingImages});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  List<File> capturedImages = [];

  @override
  void initState() {
    super.initState();
    capturedImages = List.from(widget.existingImages);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    await _controller?.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _captureImage() async {
    final image = await _controller?.takePicture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = await File(image.path).copy(path);
      setState(() {
        capturedImages.add(newImage);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void navigateToPreview() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(images: capturedImages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _captureImage,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: const Text("Capture"),
                      ),
                      ElevatedButton(
                        onPressed: navigateToPreview,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: const Text("Save & Process"),
                      ),
                    ],
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}