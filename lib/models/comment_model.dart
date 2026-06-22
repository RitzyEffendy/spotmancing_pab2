class CommentMancing {
  String id;
  String username;
  String? userId;
  String text;
  DateTime createdAt;
  String? parentId; // Digunakan jika ini adalah balasan komentar

  CommentMancing({
    required this.id,
    required this.username,
    this.userId,
    required this.text,
    required this.createdAt,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'userId': userId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  factory CommentMancing.fromMap(String id, Map<String, dynamic> map) {
    return CommentMancing(
      id: id,
      username: map['username'] ?? 'Angler',
      userId: map['userId'],
      text: map['text'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      parentId: map['parentId'],
    );
  }
}