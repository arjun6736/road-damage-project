import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routefixer/constants.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Instructions / Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome to RouteFixer 🚗",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Report road damage, help others stay safe, and make your city better.\n\n"
                    "• Detect road damages\n"
                    "• Report instantly to authorities\n"
                    "• Track damages in your way\n"
                    "• Get alerts for damages on a head\n",
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                ],
              ),

              // Login & Sign Up buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          child: ElevatedButton(
                            onPressed: () => context.goNamed('login'),
                            child: const Text("Login"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                // Border
                                color: AppColors.primary, // Border color
                                width: 2, // Border thickness
                              ),
                            ),
                            onPressed: () => context.goNamed('signup'),
                            child: const Text("Sign Up"),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: Colors.grey, // Line color
                    thickness: 1, // Line thickness
                    indent: 20, // Empty space to the left
                    endIndent: 20,
                    height: 20, // Empty space to the right
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Administrative login?'),
                      TextButton(
                        onPressed: () {
                          context.goNamed('admin_login');
                        },
                        child: const Text(
                          'Click here',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
