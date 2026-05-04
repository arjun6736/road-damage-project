// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/constants.dart';
import 'package:routefixer/widgets/app_button.dart';
import 'package:routefixer/widgets/app_inputfield.dart';
import '../services/auth_service.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final AuthService _authService = AuthService();
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  Future<void> _login() async {
    String email = _emailcontroller.text.trim();
    String password = _passwordcontroller.text.trim();
    try {
      User? user = await _authService.signin(email, password);
      if (user != null) {
        debugPrint("User logged in successfully: ${user.email}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged in!'),
            backgroundColor: Colors.green,
          ),
        );
        context.goNamed('mainpage');
      }
    } catch (e) {
      debugPrint("Login failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 30),
                          AppInputField(
                            label: "email",
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
                            label: 'password',
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
                                  "Form is valid, proceeding to login",
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
                          Divider(
                            color: Colors.grey.shade400,
                            thickness: 2,
                            height: 40,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(fontSize: 16),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.goNamed('signup');
                                },
                                child: const Text(
                                  'Sign Up',
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
