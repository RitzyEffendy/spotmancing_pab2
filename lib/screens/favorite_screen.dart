// Noval
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:spotmancing_uas_pab2/services/firebase_service.dart';
import 'package:spotmancing_uas_pab2/models/spot_model.dart';
import 'package:spotmancing_uas_pab2/screens/detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Favorit Saya')),
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
          
          if (!snapshot.hasData) {
            return const Center(child: Text('Belum ada spot favorit terpilih.'));
          }
          
          // Filter data spot yang ditandai favorit saja
          final favSpots = snapshot.data!.where((spot) => spot.isFavorite).toList();

          if (favSpots.isEmpty) {
            return const Center(child: Text('Belum ada spot favorit terpilih.'));
          }

          return ListView.builder(
            itemCount: favSpots.length,
            itemBuilder: (context, index) {
              final spot = favSpots[index];
              return ListTile(
                leading: spot.imageUrl.startsWith('data:image')
                    ? Image.memory(base64Decode(spot.imageUrl.split(',').last), width: 60, height: 60, fit: BoxFit.cover)
                    : Image.network(spot.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                title: Text(spot.name),
                subtitle: Text(spot.locationName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailScreen(spot: spot)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}