import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/user_model.dart'; 
import 'login_page.dart';
import 'my_orders_page.dart';
import 'settings_page.dart';
import 'wallet_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
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
      backgroundColor: const Color(0xFFF8F9FA), // Latar belakang lebih cerah
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("users/${currentUser?.uid}").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          String displayName = "User";
          String displayEmail = currentUser?.email ?? "";
          String? profileImageUrl;
          int walletBalance = 0;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final rawData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            UserModel userModel = UserModel.fromMap(rawData, currentUser!.uid);
            displayName = userModel.username;
            profileImageUrl = userModel.profileImageUrl;
            walletBalance = rawData['walletBalance'] ?? 0;
          }

          return SingleChildScrollView( // Agar bisa di-scroll jika layar kecil
            child: Column(
              children: [
                // 1. Header Profile Section
                _buildProfileHeader(displayName, displayEmail, profileImageUrl),

                const SizedBox(height: 20),

                // 2. Stats Section (MENGISI RUANG KOSONG)
                _buildQuickStats(walletBalance),

                const SizedBox(height: 25),

                // 3. Aktivitas Menu Group
                _buildSectionLabel("Aktivitas Saya"),
                _buildMenuOption(
                  context,
                  "Pesanan Saya",
                  "Lacak dan lihat riwayat belanja",
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersPage())),
                ),
                _buildMenuOption(
                  context,
                  "UC Wallet",
                  "Kelola saldo dan transaksi",
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletPage())),
                ),

                const SizedBox(height: 20),

                // 4. Pengaturan Menu Group
                _buildSectionLabel("Pengaturan Akun"),
                _buildMenuOption(
                  context,
                  "Ubah Profil",
                  "Edit informasi nama dan nomor telepon",
                  icon: Icons.person_outline,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                ),
                _buildMenuOption(
                  context,
                  "Bantuan & Keamanan",
                  "Pusat bantuan dan privasi",
                  icon: Icons.shield_outlined,
                  onTap: () {},
                ),

                const SizedBox(height: 40),

                // 5. Logout
                _buildLogoutButton(),
                
                const SizedBox(height: 20),
                const Text("Versi 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildProfileHeader(String name, String email, String? imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ucOrange,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(bottom: 30, left: 25, right: 25),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? (imageUrl.startsWith('data:') 
                    ? MemoryImage(Uri.parse(imageUrl).data!.contentAsBytes()) as ImageProvider
                    : NetworkImage(imageUrl))
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(Icons.person, size: 40, color: ucOrange)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Saldo Wallet", "Rp ${balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}"),
            Container(height: 30, width: 1, color: Colors.grey[200]),
            _buildStatItem("Member", "Platinum"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildMenuOption(BuildContext context, String title, String subtitle, {required IconData icon, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: ucOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: ucOrange, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}