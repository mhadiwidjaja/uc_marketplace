import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/user_model.dart'; // Import Model User
import 'login_page.dart';
import 'my_orders_page.dart';
import 'settings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  
  // Ambil user yang sedang login dari Firebase Auth
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Fungsi untuk Logout secara aman
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigasi ke LoginPage dan hapus semua tumpukan halaman sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Profile Info Section dengan StreamBuilder & Model
          StreamBuilder(
            // Mendengarkan perubahan data user spesifik berdasarkan UID
            stream: FirebaseDatabase.instance.ref("users/${currentUser?.uid}").onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              // Default UI saat memuat atau jika data tidak ditemukan
              String displayName = "Memuat...";
              String displayEmail = currentUser?.email ?? "Email tidak tersedia";

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                // Konversi data mentah Firebase ke Map
                final rawData = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map
                );
                
                // Gunakan Model untuk memproses data
                UserModel userModel = UserModel.fromMap(rawData, currentUser!.uid);
                displayName = userModel.username;
              }

              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar Pengguna
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: const NetworkImage(
                        "https://i.pravatar.cc/150?img=5", // Placeholder image
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Informasi Nama dan Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 15),

          // 2. Menu Options
          _buildMenuOption(
            context,
            "My orders",
            "Lihat riwayat belanja Anda",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersPage()),
              );
            },
          ),
          _buildMenuOption(
            context,
            "Settings",
            "Atur profil dan preferensi",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),

          const Spacer(), // Mendorong tombol logout ke bawah

          // 3. Logout Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: _handleLogout,
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 10),
                  Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

  // Helper Widget untuk Item Menu
  Widget _buildMenuOption(
    BuildContext context,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1), // Garis pemisah tipis
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}