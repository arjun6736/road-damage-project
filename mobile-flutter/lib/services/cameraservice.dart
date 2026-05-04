import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription> cameras = [];
  CameraController? _controller;

  /// Call this in main.dart so the service knows about the cameras
  void setCameras(List<CameraDescription> cams) {
    cameras = cams;
  }

  Future<void> init(CameraDescription camera) async {
    if (_controller != null && _controller!.value.isInitialized) return;

    _controller = CameraController(
      camera,
      ResolutionPreset.high, // High res for good details before cropping
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.jpeg
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
  }

  CameraController? get controller => _controller;

  Future<File> captureYoloReady() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('Camera not initialized');
    }

    // 1. Capture High-Res Image
    final XFile raw = await _controller!.takePicture();
    final rawBytes = await raw.readAsBytes();

    // 2. Process in Background Isolate (Prevents UI Freeze)
    final processedBytes = await compute(_processImageInIsolate, rawBytes);

    // 3. Save to Temp File
    final tmpDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outFile = File('${tmpDir.path}/YOLO_$timestamp.jpg');
    await outFile.writeAsBytes(processedBytes);

    return outFile;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

// --- BACKGROUND PROCESSING LOGIC ---

Uint8List _processImageInIsolate(Uint8List inputBytes) {
  // Decode
  img.Image? original = img.decodeImage(inputBytes);
  if (original == null) throw Exception("Failed to decode image");

  // CRITICAL FIX: Bake Orientation
  // This rotates the image pixels to match how the user held the phone (Portrait/Landscape)
  original = img.bakeOrientation(original);

  // 1. Auto-Brightness
  original = _applyAutoBrightness(original);

  // 2. Center Crop (Square)
  final int size = math.min(original.width, original.height);
  final int offsetX = (original.width - size) ~/ 2;
  final int offsetY = (original.height - size) ~/ 2;

  final img.Image cropped = img.copyCrop(
    original,
    x: offsetX,
    y: offsetY,
    width: size,
    height: size,
  );

  // 3. Resize to 640x640 (Standard YOLO Input)
  final img.Image resized = img.copyResize(
    cropped,
    width: 640,
    height: 640,
    interpolation: img.Interpolation.linear,
  );

  // Encode to JPEG
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

img.Image _applyAutoBrightness(img.Image src) {
  // Calculate Mean Luma
  double totalLuma = 0;
  for (final pixel in src) {
    totalLuma += 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
  }

  // Normalize mean luma to 0.0 - 1.0 range
  final meanLuma = (totalLuma / (src.width * src.height)) / 255.0;

  // If brightness is already good (between 0.35 and 0.65), skip processing
  if (meanLuma >= 0.35 && meanLuma <= 0.65) return src;

  // Gamma Correction
  final gamma = (math.log(0.5) / math.log(meanLuma)).clamp(0.4, 2.5);

  // Create Lookup Table (LUT) for speed
  final lut = List<int>.generate(
    256,
    (i) => ((math.pow(i / 255.0, gamma) * 255.0).round()).clamp(0, 255),
  );

  // Apply LUT to pixels
  for (final pixel in src) {
    pixel.r = lut[pixel.r.toInt()];
    pixel.g = lut[pixel.g.toInt()];
    pixel.b = lut[pixel.b.toInt()];
  }
  return src;
}
