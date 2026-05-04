import 'package:flutter/material.dart';

/// Centralized color palette for the app.
/// Change colors here to update everywhere.
class AppColors {
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color secondary = Color(0xFF42A5F5); // Light Blue
  static const Color accent = Color(0xFFFF9800); // Orange
  static const Color background = Color(0xFFF5F5F5); // Light grey
  static const Color textPrimary = Color(0xFF212121); // Almost black
  static const Color textSecondary = Color(0xFF757575); // Grey
  static const Color error = Color(0xFFD32F2F); // Red
}

/// Commonly used strings in the app.
/// Helps in localization and consistency.
class AppText {
  static const String appName = "Road Damage Detection";
  static const String login = "Login";
  static const String signup = "Sign Up";
  static const String welcomeTitle = "Welcome to Road Damage Detection";
  static const String welcomeSubtitle =
      "Report, track, and manage road damage with ease.";
  static const String email = "Email";
  static const String password = "Password";
  static const String adminLogin = "Admin Login";
}
