// Ritzy
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:spotmancing_pab2/services/firebase_service.dart';
import 'package:spotmancing_pab2/services/theme_provider.dart';
import 'package:spotmancing_pab2/models/spot_model.dart';
import 'package:spotmancing_pab2/screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentUsername = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileData = await FirebaseService().getUserProfile();
      if (profileData != null && mounted) {
        setState(() {
          _currentUsername = profileData['username'] ?? widget.username;
          _profileImageUrl = profileData['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  void _showMiniProfile(BuildContext context) {
    String initialLetter = _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : 'U';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _profileImageUrl != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl!.startsWith('data:image')
                          ? MemoryImage(base64Decode(_profileImageUrl!.split(',').last)) as ImageProvider
                          : NetworkImage(_profileImageUrl!),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Text(
                _currentUsername,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bergabung sejak: 25 Mei 2026',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eksplor Spot Mancing'),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: _profileImageUrl != null
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: _profileImageUrl!.startsWith('data:image')
                        ? MemoryImage(base64Decode(_profileImageUrl!.split(',').last)) as ImageProvider
                        : NetworkImage(_profileImageUrl!),
                  )
                : const Icon(Icons.person),
            onPressed: () => _showMiniProfile(context),
          ),
        ],
      ),
      body: StreamBuilder<List<SpotMancing>>(
        stream: FirebaseService().getSpots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan:\n${snapshot.error}', textAlign: TextAlign.center));
          }
          // Jika loading dan belum pernah dapat data
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Jika tidak ada data sama sekali
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada spot mancing yang dibagikan.'));
          }

          final spots = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: spots.length,
              itemBuilder: (context, index) {
                final spot = spots[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailScreen(spot: spot)),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: spot.imageUrl.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(spot.imageUrl.split(',').last),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                            )
                          : Image.network(
                              spot.imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            spot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                          child: Text(
                            spot.locationName,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}