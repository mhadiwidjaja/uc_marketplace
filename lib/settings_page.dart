import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html; // Library untuk menangani upload di Web (localhost)

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final Color ucOrange = const Color(0xFFF39C12);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  XFile? _pickedFile; 
  Uint8List? _webImage; // Data gambar khusus untuk Web
  String? _currentImageUrl;
  bool _isLoading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Ambil data user dari Realtime Database
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/${currentUser!.uid}");
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _nameController.text = data['username'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _emailController.text = data['email'] ?? (currentUser!.email ?? '');
        _currentImageUrl = data['profileImageUrl'];
      });
    }
  }

  // Fungsi Pilih Gambar (Mendukung Web & Mobile + Kompresi)
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Menggunakan dart:html untuk stabilitas di browser localhost
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.length == 1) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            setState(() {
              _webImage = reader.result as Uint8List;
              _pickedFile = XFile(file.name); 
            });
          });
        }
      });
    } else {
      // Standar Mobile dengan kompresi agar upload cepat
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25, // Kompresi 25% agar ukuran file kecil
      );
      if (image != null) {
        setState(() => _pickedFile = image);
      }
    }
  }

  // Simpan data ke Firebase
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    String? imageUrl = _currentImageUrl;

    try {
      // Proses Upload ke Firebase Storage
      if (_webImage != null || _pickedFile != null) {
        Reference ref = FirebaseStorage.instance.ref("profile_pics/${currentUser!.uid}.jpg");
        
        if (kIsWeb && _webImage != null) {
          await ref.putData(_webImage!);
        } else if (_pickedFile != null) {
          await ref.putFile(File(_pickedFile!.path));
        }
        imageUrl = await ref.getDownloadURL();
      }

      // Update data di Realtime Database
      await FirebaseDatabase.instance.ref("users/${currentUser!.uid}").update({
        'username': _nameController.text,
        'phoneNumber': _phoneController.text,
        'profileImageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengunggah: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ucOrange, 
        elevation: 0,
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ucOrange),
              const SizedBox(height: 15),
              const Text("Sedang mengunggah data...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ) 
      : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Bagian Foto Profil
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                          ),
                          child: ClipOval(child: _displayImage()),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundColor: ucOrange, 
                              radius: 20,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tombol "Ubah"
                    SizedBox(
                      height: 35,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                        label: const Text("Ubah", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: const StadiumBorder()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Input Nama
              _buildLabel("Full Name"),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Nama Lengkap"),
                validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 20),

              // Input Email (Read-only)
              _buildLabel("Email Address"),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: _inputDecoration("email@mail.com").copyWith(filled: true, fillColor: Colors.grey[100]),
              ),
              const SizedBox(height: 20),

              // Input Telepon (Wajib Indonesia)
              _buildLabel("Phone Number"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("08xxxxxxxxxx").copyWith(prefixIcon: const Icon(Icons.phone_android, size: 20)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nomor telepon wajib diisi';
                  RegExp regExp = RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{7,11}$');
                  if (!regExp.hasMatch(value)) return 'Gunakan format Indonesia (08...)';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Tombol Save
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _saveProfile,
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logika tampilan gambar
  Widget _displayImage() {
    if (_webImage != null) return Image.memory(_webImage!, fit: BoxFit.cover);
    if (_pickedFile != null && !kIsWeb) return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
    if (_currentImageUrl != null) return Image.network(_currentImageUrl!, fit: BoxFit.cover);
    return const Icon(Icons.person, size: 80, color: Colors.grey);
  }

  Widget _buildLabel(String text) => Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}