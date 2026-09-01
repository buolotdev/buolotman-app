import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

enum CameraMode { idCard, selfie }

class CustomCameraScreen extends StatefulWidget {
  final CameraMode mode;

  const CustomCameraScreen({super.key, required this.mode});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  String _scanStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // For selfie, prefer front camera. For ID, prefer back camera.
      CameraDescription selectedCamera = _cameras!.firstWhere(
        (camera) => widget.mode == CameraMode.selfie
            ? camera.lensDirection == CameraLensDirection.front
            : camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndVerify() async {
    if (!_controller!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
      _scanStatus = widget.mode == CameraMode.idCard
          ? 'Scanning National ID...'
          : 'Analyzing facial features...';
    });

    try {
      final XFile picture = await _controller!.takePicture();

      // Simulate AI Verification delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _scanStatus = widget.mode == CameraMode.idCard
            ? 'ID Recognized Successfully!'
            : 'Face Verified Successfully!';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(picture.path);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Error capturing image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Custom Overlay (Rectangle or Circle)
          Positioned.fill(
            child: CustomPaint(
              painter: OverlayPainter(mode: widget.mode),
            ),
          ),

          // 3. Instructions Text
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Text(
              widget.mode == CameraMode.idCard
                  ? 'Align your National ID within the frame'
                  : 'Position your face within the circle',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),

          // 4. Scanning Status Indicator
          if (_isScanning)
            Positioned(
              bottom: 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _scanStatus,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                GestureDetector(
                  onTap: _isScanning ? null : _takePictureAndVerify,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isScanning ? Colors.grey : Colors.white30,
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isScanning ? Colors.grey : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Spacer for balance
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the Guideline Overlays
class OverlayPainter extends CustomPainter {
  final CameraMode mode;

  OverlayPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    // Create a full-screen path
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path cutoutPath = Path();

    if (mode == CameraMode.idCard) {
      // Draw a horizontal rectangle for ID
      final double rectWidth = size.width * 0.85;
      final double rectHeight = rectWidth * 0.63; // Standard ID card ratio
      final double left = (size.width - rectWidth) / 2;
      final double top = (size.height - rectHeight) / 2;

      cutoutPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, rectWidth, rectHeight),
        const Radius.circular(12),
      ));
    } else {
      // Draw a circle for selfie
      final double radius = size.width * 0.4;
      final Offset center = Offset(size.width / 2, size.height / 2 - 50);

      cutoutPath.addOval(Rect.fromCircle(center: center, radius: radius));
    }

    // Combine paths using difference to create the "hole"
    final overlayPath = Path.combine(PathOperation.difference, path, cutoutPath);
    canvas.drawPath(overlayPath, paint);

    // Draw the guideline border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(cutoutPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
