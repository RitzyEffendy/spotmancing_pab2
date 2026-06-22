class SpotMancing {
  String id;
  String name;
  String description;
  String locationName;
  double latitude;
  double longitude;
  String waterCondition; // "Pasang" atau "Surut"
  String imageUrl;
  bool isFavorite;
  DateTime createdAt;
  String jenisIkan;
  String rekomendasiUmpan;

  SpotMancing({
    required this.id,
    required this.name,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.waterCondition,
    required this.imageUrl,
    this.isFavorite = false,
    required this.createdAt,
    required this.jenisIkan,
    required this.rekomendasiUmpan,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'waterCondition': waterCondition,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'jenisIkan': jenisIkan,
      'rekomendasiUmpan': rekomendasiUmpan,
    };
  }

  factory SpotMancing.fromMap(String id, Map<String, dynamic> map) {
    return SpotMancing(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : 0.0,
      waterCondition: map['waterCondition'] ?? 'Pasang',
      imageUrl: map['imageUrl'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      jenisIkan: map['jenisIkan'] ?? '',
      rekomendasiUmpan: map['rekomendasiUmpan'] ?? '',
    );
  }
}