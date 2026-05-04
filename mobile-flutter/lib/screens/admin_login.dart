// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/constants.dart';
import 'package:routefixer/services/auth_service.dart';
import 'package:routefixer/widgets/app_button.dart';
import 'package:routefixer/widgets/app_inputfield.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final AuthService _authService = AuthService();
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  // ✅ Allowed admin accounts
  final List<String> adminEmails = ["admin1@gmail.com", "admin2@gmail.com"];

  Future<void> _login() async {
    String email = _emailcontroller.text.trim();
    String password = _passwordcontroller.text.trim();

    try {
      User? user = await _authService.signin(email, password);

      if (user != null) {
        // ✅ Check if the logged-in email is in admin list
        if (adminEmails.contains(user.email)) {
          debugPrint("Admin logged in successfully: ${user.email}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          context.goNamed('mainpage'); // Navigate to admin main page
        } else {
          // ❌ Not an admin → sign out
          await FirebaseAuth.instance.signOut();
          debugPrint("Access denied: ${user.email} is not an admin.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Access denied: Admins only"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Login failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect Username or Password"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteFixer'),
        leading: IconButton(
          onPressed: () {
            context.goNamed('intro');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.all(30),
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formkey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Admin Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 30),
                          AppInputField(
                            label: "Email",
                            controller: _emailcontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your email";
                              }
                              if (!value.contains('@')) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AppInputField(
                            label: 'Password',
                            controller: _passwordcontroller,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your password";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              context.goNamed('reset-password');
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppElevatedButton(
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                debugPrint(
                                  "Form is valid, proceeding to admin login",
                                );
                                _login();
                              } else {
                                debugPrint("Form is not valid");
                              }
                            },
                            label: 'Login',
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
