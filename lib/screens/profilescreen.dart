import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: 20),
          // Profile Header
          Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : const AssetImage("assets/images/person.png")
                          as ImageProvider,
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ?? "Guest User",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user?.phoneNumber ?? user?.email ?? "No contact info",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
            ],
          ),

          const Divider(),

          // Options
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Edit Profile"),
            onTap: () {
              context.pushNamed("editProfile"); // you can create this page
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.deepPurple),
            title: const Text("Settings"),
            onTap: () {
              context.pushNamed("settings");
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: const Text("Notifications"),
            onTap: () {
              context.pushNamed("notifications");
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.teal),
            title: const Text("Help & Support"),
            onTap: () {
              context.pushNamed("help");
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.goNamed("login"); // redirect to login page
              }
            },
          ),
        ],
      ),
    );
  }
}
