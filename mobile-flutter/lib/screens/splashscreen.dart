import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Keep native splash while loading
    await Future.delayed(const Duration(seconds: 2));

    // Get the current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    // Remove the native splash screen
    FlutterNativeSplash.remove();

    // Navigate based on user state
    if (!mounted) return;
    if (user != null) {
      context.goNamed('mainpage');
    } else {
      context.goNamed('intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    // No extra UI — native splash will cover this
    return Container(
      color: Colors.white, // match your native splash background
      alignment: Alignment.center,
    );
  }
}
