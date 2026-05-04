import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:camera/camera.dart';
import 'package:routefixer/app_theme.dart';
import 'package:routefixer/routes.dart';
import 'package:routefixer/services/cameraservice.dart';
import 'package:routefixer/services/fcm_service.dart';

List<CameraDescription>? cameras; // global list of cameras

Future<void> main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Initialize Firebase
  await Firebase.initializeApp();
  await FCMService.init();
  // Initialize cameras
  cameras = await availableCameras();
  CameraService().setCameras(cameras!);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Road Damage Detection',
      theme: AppTheme.lightTheme,
      routerConfig: router, // routes.dart must use cameras
    );
  }
}
