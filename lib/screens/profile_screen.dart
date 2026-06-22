// Marcell
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:spotmancing_pab2/screens/login_screen.dart';
import 'package:spotmancing_pab2/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  final String _joinedDate = "25 Mei 2026";
  XFile? _selectedImage; // Gambar baru yang dipilih user
  String? _profileImageUrl; // URL gambar dari Firebase
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.username);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileData = await FirebaseService().getUserProfile();
      if (profileData != null && mounted) {
        setState(() {
          if (profileData['profileImageUrl'] != null) {
            _profileImageUrl = profileData['profileImageUrl'];
          }
          _nameController.text = profileData['username'] ?? widget.username;
        });
      }
    } catch (e) {
      // Silently fail jika user tidak authenticated
      if (!e.toString().contains('User tidak ditemukan')) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  String _getInitialLetter() {
    return _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U';
  }

  Widget _buildProfileAvatar() {
    // Jika ada gambar baru yang dipilih user
    if (_selectedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return CircleAvatar(radius: 50, child: const CircularProgressIndicator());
        },
      );
    }
    
    // Jika ada gambar yang tersimpan di Firebase
    if (_profileImageUrl != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: _profileImageUrl!.startsWith('data:image')
            ? MemoryImage(base64Decode(_profileImageUrl!.split(',').last)) as ImageProvider
            : NetworkImage(_profileImageUrl!),
      );
    }

    // Default avatar dengan initial huruf
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blue,
      child: Text(
        _getInitialLetter(),
        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseService().updateUserProfile(_nameController.text, _selectedImage);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _selectedImage = null; // Clear selected image setelah disimpan
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );

        // Reload profil untuk mengupdate image URL dari Firebase
        await _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String errorMessage = e.toString();
        if (errorMessage.contains('Silakan login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan login terlebih dahulu')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorMessage')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _buildProfileAvatar(),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Pengguna', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Text(
                "Bergabung sejak: $_joinedDate",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Perubahan'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Keluar Akun'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              }
                            },
                            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Akun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}