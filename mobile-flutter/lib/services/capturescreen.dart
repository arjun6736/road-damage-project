import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart';
import 'package:routefixer/services/cameraservice.dart';
// REPLACE with your actual path

class CapturePage extends StatefulWidget {
  final CameraDescription camera;
  const CapturePage({super.key, required this.camera});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> with WidgetsBindingObserver {
  CameraController? controller;
  bool isCameraInitialized = false;
  bool isCapturing = false;
  String? statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await CameraService().init(widget.camera);
      controller = CameraService().controller;
      if (mounted) setState(() => isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _handleCapture() async {
    if (isCapturing) return;

    setState(() {
      isCapturing = true;
      statusMessage = "Acquiring GPS...";
    });

    try {
      // 1. Check GPS
      if (!await _checkGPS()) {
        throw Exception("GPS disabled or permission denied");
      }

      setState(() => statusMessage = "Processing Image...");

      // 2. Capture & Process (Returns 640x640 file)
      final processedFile = await CameraService().captureYoloReady();

      // 3. Get Metadata
      setState(() => statusMessage = "Finalizing...");
      final pos = await Geolocator.getCurrentPosition();
      final time = DateTime.now().toIso8601String();

      // 4. Navigate to details page
      if (mounted) {
        context.pushNamed(
          'addDetails', // Ensure this route exists in your GoRouter config
          extra: {
            "imageFile": processedFile,
            "gps": "${pos.latitude}, ${pos.longitude}",
            "time": time,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
          statusMessage = null;
        });
      }
    }
  }

  Future<bool> _checkGPS() async {
    final location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return false;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return false;
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CameraService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final deviceRatio = size.width / size.height;

    // Calculate the square size based on width
    final double squareSize = size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Capture Road Damage"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),

              // --- SQUARE VIEWFINDER ---
              // This container clips the camera preview to a perfect square.
              Center(
                child: Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover, // Ensures center crop visual
                        child: SizedBox(
                          width: squareSize,
                          // This height calculation ensures the preview aspect ratio is maintained
                          // so the FittedBox can crop it correctly.
                          height: squareSize * controller!.value.aspectRatio,
                          child: CameraPreview(controller!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- INSTRUCTIONS ---
              Expanded(
                child: Center(
                  child: isCapturing
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              statusMessage ?? "Processing...",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : const Text(
                          "Align damage inside the square",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: isCapturing ? null : _handleCapture,
        backgroundColor: isCapturing ? Colors.grey[800] : Colors.white,
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
      ),
    );
  }
}
