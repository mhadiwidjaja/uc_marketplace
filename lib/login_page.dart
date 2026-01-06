import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color ucOrange = const Color(0xFFF39C12);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email dan Password tidak boleh kosong")),
        );
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login gagal. Silakan coba lagi.";
      if (e.code == 'user-not-found') {
        message = "Pengguna tidak ditemukan.";
      } else if (e.code == 'wrong-password') message = "Kata sandi salah.";
      else if (e.code == 'invalid-email') message = "Format email tidak valid.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 30),
                  _buildLabel("Email Address"),
                  _buildInputField("email@student.uc.ac.id", controller: _emailController, autofillHints: const [AutofillHints.email]),
                  const SizedBox(height: 20),
                  _buildLabel("Password"),
                  _buildInputField("********", controller: _passwordController, isPassword: true, autofillHints: const [AutofillHints.password]),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _handleLogin,
                      child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage())),
                        child: Text("Sign up", style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _buildInputField(String placeholder, {required TextEditingController controller, bool isPassword = false, List<String>? autofillHints}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller, 
        obscureText: isPassword,
        autofillHints: autofillHints,
        decoration: InputDecoration(hintText: placeholder, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }
}