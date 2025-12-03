import 'package:flutter/material.dart';
import 'login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text("Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Profile Info Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Circular Avatar
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=5"), // Dummy online image
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Matilda Brown",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "matildabrown@mail.com",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // 2. Menu Options
          _buildMenuOption(context, "My orders", "Already have 12 orders"),
          _buildMenuOption(context, "Settings", "Personal Settings"),

          const Spacer(), // Pushes Logout to bottom

          // 3. Logout Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () {
                // Return to Login Page and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    "Logout",
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String title, String subtitle) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1), // Tiny gap for separator effect
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to specific pages later
        },
      ),
    );
  }
}