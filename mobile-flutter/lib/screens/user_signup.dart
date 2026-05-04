// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/constants.dart';
import 'package:routefixer/widgets/app_button.dart';
import 'package:routefixer/widgets/app_inputfield.dart';
import '../services/auth_service.dart';

class UserSignup extends StatefulWidget {
  const UserSignup({super.key});

  @override
  State<UserSignup> createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> {
  final AuthService _authService = AuthService();
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();
  final TextEditingController _namecontroller = TextEditingController();

  Future<void> _signup() async {
    String email = _emailcontroller.text.trim();
    String password = _passwordcontroller.text.trim();
    String name = _namecontroller.text.trim();
    try {
      User? user = await _authService.signup(email, password, name);
      if (user != null) {
        debugPrint("User signed up successfully: ${user.email}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed up!'),
            backgroundColor: Colors.green,
          ),
        );
        context.goNamed('mainpage');
      }
    } catch (e) {
      debugPrint("Sign up failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign Up Failed"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteFixer'),
        leading: IconButton(
          onPressed: () => context.goNamed('intro'),
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
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Name
                          AppInputField(
                            label: "Name",
                            controller: _namecontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your name";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Email
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

                          // Password
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

                          const SizedBox(height: 20),

                          // Sign Up Button
                          AppElevatedButton(
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                debugPrint(
                                  "Form is valid — proceed with sign up",
                                );
                                _signup();
                              } else {
                                debugPrint("Form is not valid");
                              }
                            },
                            label: 'Sign Up',
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 30,
                            ),
                          ),

                          Divider(
                            color: Colors.grey.shade400,
                            thickness: 2,
                            height: 40,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(fontSize: 16),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.goNamed('login');
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
