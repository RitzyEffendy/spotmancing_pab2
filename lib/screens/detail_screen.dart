// Noval
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:spotmancing_uas_pab2/models/spot_model.dart';
import 'package:spotmancing_uas_pab2/models/comment_model.dart';
import 'package:spotmancing_uas_pab2/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailScreen extends StatefulWidget {
  final SpotMancing spot;
  const DetailScreen({super.key, required this.spot});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentController = TextEditingController();
  CommentMancing? replyingTo;

  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              FirebaseService().deleteComment(widget.spot.id, commentId);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot.name),
        actions: [
          IconButton(
            icon: Icon(
              widget.spot.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.spot.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              await FirebaseService().toggleFavorite(widget.spot.id, widget.spot.isFavorite);
              setState(() {
                widget.spot.isFavorite = !widget.spot.isFavorite;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.spot.imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(widget.spot.imageUrl.split(',').last),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        )
                      : Image.network(widget.spot.imageUrl, width: double.infinity, height: 220, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  Text(widget.spot.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Lokasi: ${widget.spot.locationName}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("Koordinat GPS: ${widget.spot.latitude}, ${widget.spot.longitude}", style: const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text("Kondisi Air: ${widget.spot.waterCondition}"),
                    backgroundColor: widget.spot.waterCondition == "Pasang" ? Colors.blue.shade100 : Colors.amber.shade100,
                  ),
                  const Divider(height: 32),
                  const Text("Deskripsi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.spot.description, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 32),
                  const Text("Detail Informasi Mancing:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.set_meal, color: Colors.white),
                    ),
                    title: const Text("Jenis Ikan"),
                    subtitle: Text(widget.spot.jenisIkan.isNotEmpty ? widget.spot.jenisIkan : "-"),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.anchor, color: Colors.white),
                    ),
                    title: const Text("Rekomendasi Umpan"),
                    subtitle: Text(widget.spot.rekomendasiUmpan.isNotEmpty ? widget.spot.rekomendasiUmpan : "-"),
                  ),
                  const Divider(height: 32),
                  const Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // List Komentar & Balasan
                  StreamBuilder<List<CommentMancing>>(
                    stream: FirebaseService().getComments(widget.spot.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final allComments = snapshot.data!;
                      final mainComments = allComments.where((c) => c.parentId == null).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: mainComments.length,
                        itemBuilder: (context, index) {
                          final mainComment = mainComments[index];
                          final replies = allComments.where((c) => c.parentId == mainComment.id).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                ListTile(
                                  title: Text(mainComment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(mainComment.text),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (FirebaseAuth.instance.currentUser?.uid == mainComment.userId && mainComment.userId != null)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _confirmDeleteComment(mainComment.id),
                                        ),
                                      TextButton(
                                        onPressed: () => setState(() => replyingTo = mainComment),
                                        child: const Text('Balas'),
                                      ),
                                    ],
                                  ),
                                ),
                              // Render Balasan (Indentasi)
                              ...replies.map((reply) => Padding(
                                    padding: const EdgeInsets.only(left: 40.0),
                                    child: ListTile(
                                      title: Text(reply.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(reply.text, style: const TextStyle(fontSize: 14)),
                                      trailing: FirebaseAuth.instance.currentUser?.uid == reply.userId && reply.userId != null
                                          ? IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                              onPressed: () => _confirmDeleteComment(reply.id),
                                            )
                                          : null,
                                    ),
                                  )),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Kolom ketik komentar
          if (replyingTo != null)
            Container(
              color: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text("Membalas ${replyingTo!.username}"),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => replyingTo = null))
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Tulis komentar atau balasan...', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      final comment = CommentMancing(
                        id: '',
                        username: FirebaseAuth.instance.currentUser?.displayName ?? 'Pengguna',
                        userId: FirebaseAuth.instance.currentUser?.uid,
                        text: _commentController.text,
                        createdAt: DateTime.now(),
                        parentId: replyingTo?.id,
                      );
                      FirebaseService().addComment(widget.spot.id, comment);
                      _commentController.clear();
                      setState(() => replyingTo = null);
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}