import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:spotmancing_pab2/models/spot_model.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:spotmancing_pab2/models/comment_model.dart';

class FirebaseService {
  final CollectionReference spotCollection = FirebaseFirestore.instance.collection('spots');

  // Stream data spot mancing
  Stream<List<SpotMancing>> getSpots() {
    return spotCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SpotMancing.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Tambah Spot Mancing Baru beserta upload gambar (BYPASS STORAGE -> BASE64)
  Future<void> addSpot(SpotMancing spot, XFile imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // Mengubah gambar menjadi string Base64
      String base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      
      // Firestore memiliki batas maksimal 1MB per dokumen. 
      // Jika string Base64 lebih dari 900KB, tolak sebelum membuat aplikasi macet/loading abadi.
      if (base64Image.length > 900000) {
        throw Exception('Resolusi foto terlalu tinggi (melebihi 700KB). Karena Firebase Storage terkunci, aplikasi mencoba menyimpan via Database, namun tertahan oleh batas ukuran maksimum 1MB. Solusi: Gunakan foto berukuran lebih kecil, ATAU buat Firebase Project baru dengan lokasi server di Amerika (us-central) agar Firebase Storage gratis bisa digunakan.');
      }
      
      spot.imageUrl = base64Image;
      await spotCollection.add(spot.toMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Koneksi Database Timeout! Apakah kamu sudah mengaktifkan "Firestore Database" di Firebase Console? Jika belum, wajib klik "Create Database" di menu Firestore terlebih dahulu.');
        },
      );
    } catch (e) {
      throw Exception('Gagal memproses gambar: $e');
    }
  }

  // Update Status Favorit
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await spotCollection.doc(id).update({'isFavorite': !currentStatus});
  }

  // Tambah Komentar atau Balasan
  Future<void> addComment(String spotId, CommentMancing comment) async {
    await spotCollection.doc(spotId).collection('comments').add(comment.toMap());
  }

  // Stream Komentar per Spot
  Stream<List<CommentMancing>> getComments(String spotId) {
    return spotCollection
        .doc(spotId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentMancing.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Hapus Komentar
  Future<void> deleteComment(String spotId, String commentId) async {
    // Optional: Kita juga bisa menghapus balasan dari komentar ini, 
    // tapi untuk sederhananya, hapus saja dokumen komentarnya.
    await spotCollection.doc(spotId).collection('comments').doc(commentId).delete();
  }

  // Upload dan simpan profil user
  Future<void> updateUserProfile(String username, XFile? profileImage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu');
    }

    String? imageUrl;
    
    // Ubah gambar menjadi Base64 jika ada
    if (profileImage != null) {
      final imageBytes = await profileImage.readAsBytes();
      imageUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    }

    // Simpan data profil ke Firestore
    final userProfileRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final Map<String, dynamic> profileData = {
      'username': username,
      'email': user.email,
      'updatedAt': DateTime.now(),
    };

    if (imageUrl != null) {
      profileData['profileImageUrl'] = imageUrl;
    }

    await userProfileRef.set(profileData, SetOptions(merge: true));
  }

  // Ambil data profil user
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null; // Return null jika user tidak login
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
}