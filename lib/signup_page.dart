import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/user_model.dart'; // Pastikan import model ini benar
import 'login_page.dart';
import 'main_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignUp() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi semua bidang")));
        return;
      }

      // 1. Buat user di Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Siapkan data menggunakan Model
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // 3. Simpan ke Realtime Database
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/${newUser.uid}");
      await ref.set(newUser.toMap());

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'email-already-in-use') message = "Email sudah digunakan.";
      else if (e.code == 'weak-password') message = "Kata sandi terlalu lemah.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, height: 120, color: ucOrange, alignment: Alignment.center,
              child: const SafeArea(child: Text("UC Marketplace", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sign up", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 30),
                  _buildLabel("Username"),
                  _buildInputField("Nama Lengkap", controller: _usernameController),
                  const SizedBox(height: 20),
                  _buildLabel("Email Address"),
                  _buildInputField("email@gmail.com", controller: _emailController),
                  const SizedBox(height: 20),
                  _buildLabel("Password"),
                  _buildInputField("********", controller: _passwordController, isPassword: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _handleSignUp,
                      child: const Text("Sign up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                      child: Text("Sudah punya akun? Login", style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  
  Widget _buildInputField(String placeholder, {required TextEditingController controller, bool isPassword = false}) {
    return TextField(
      controller: controller, obscureText: isPassword,
      decoration: InputDecoration(hintText: placeholder, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
    );
  }
}