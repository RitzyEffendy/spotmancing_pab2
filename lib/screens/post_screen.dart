// Darma
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spotmancing_pab2/models/spot_model.dart';
import 'package:spotmancing_pab2/services/firebase_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locNameCtrl = TextEditingController();
  final _fishTypeCtrl = TextEditingController();
  final _baitCtrl = TextEditingController();
  String _waterCondition = 'Pasang';
  
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  XFile? _selectedImage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locNameCtrl.dispose();
    _fishTypeCtrl.dispose();
    _baitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _submitPost() async {
    if (_nameCtrl.text.isEmpty || _latitude == null || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field, GPS, dan Foto wajib diisi/diambil')),
      );
      return;
    }

    final newSpot = SpotMancing(
      id: '',
      name: _nameCtrl.text,
      description: _descCtrl.text,
      locationName: _locNameCtrl.text,
      latitude: _latitude!,
      longitude: _longitude!,
      waterCondition: _waterCondition,
      imageUrl: '', // Diproses di service
      createdAt: DateTime.now(),
      jenisIkan: _fishTypeCtrl.text,
      rekomendasiUmpan: _baitCtrl.text,
    );

    if (!mounted) return;
    
    // Menampilkan loading indikator saat upload data ke firebase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseService().addSpot(newSpot, _selectedImage!);
      
      if (!mounted) return;
      
      // Tutup loading dialog
      Navigator.pop(context);
      
      // Reset form
      _nameCtrl.clear();
      _descCtrl.clear();
      _locNameCtrl.clear();
      _fishTypeCtrl.clear();
      _baitCtrl.clear();
      setState(() {
        _selectedImage = null;
        _latitude = null;
        _longitude = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spot mancing berhasil diposting!')),
      );
      
      // Tidak perlu Navigator.pop di sini karena PostScreen adalah bagian dari BottomNavigationBar, 
      // bukan dipanggil lewat Navigator.push. Memanggil pop di sini akan mengeluarkan user dari aplikasi (Black Screen).
      
    } catch (e) {
      if (!mounted) return;
      
      // Tutup loading dialog jika masih terbuka
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Spot Mancing Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dummy Selector Box Pengganti Image Picker untuk demonstrasi alur
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey.shade300,
                child: _selectedImage == null 
                    ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : FutureBuilder<Uint8List>(
                        future: _selectedImage!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(snapshot.data!, fit: BoxFit.cover);
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Spot', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _locNameCtrl, decoration: const InputDecoration(labelText: 'Nama Daerah/Lokasi', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi Spot', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _waterCondition,
              decoration: const InputDecoration(labelText: 'Kondisi Air', border: OutlineInputBorder()),
              items: ['Pasang', 'Surut'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => _waterCondition = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fishTypeCtrl,
              decoration: const InputDecoration(
                labelText: 'Jenis Ikan (misal: Kakap, Baronang)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.set_meal),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baitCtrl,
              decoration: const InputDecoration(
                labelText: 'Rekomendasi Umpan (misal: Udang Hidup, Cacing)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.anchor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_latitude == null 
                      ? "Koordinat GPS belum diambil" 
                      : "Lat: $_latitude, Long: $_longitude",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(_isLoadingLocation ? "Mencari..." : "Ambil GPS"),
                )
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Bagikan Spot'),
            ),
          ],
        ),
      ),
    );
  }
}