class PlantModel {
  final String id;
  final String name;
  final String species;
  final String type;
  final String location;
  final String moisture;
  final String temperature;
  final String status;
  final String lastUpdated;
  final String soilPreference;
  final String lightRequirement;
  final String wateringFrequency;

  // Cloudinary image URL
  final String imageUrl;

  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;

  final DateTime addedDate;
  final DateTime createdAt;

  PlantModel({
    required this.id,
    required this.name,
    this.species = '',
    this.type = '',
    this.location = '',
    this.moisture = '0%',
    this.temperature = '0°C',
    this.status = 'Normal',
    this.lastUpdated = 'Just now',
    this.soilPreference = '',
    this.lightRequirement = '',
    this.wateringFrequency = '',
    this.imageUrl = '',
    this.minTemp = 0.0,
    this.maxTemp = 40.0,
    this.minHumidity = 0.0,
    this.maxHumidity = 100.0,
    DateTime? addedDate,
    DateTime? createdAt,
  })  : addedDate = addedDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory PlantModel.fromMap(dynamic idOrMap, [dynamic mapOrId]) {
    final String documentId;
    final Map<dynamic, dynamic> map;

    if (idOrMap is String && mapOrId is Map) {
      documentId = idOrMap;
      map = mapOrId;
    } else if (idOrMap is Map && mapOrId is String) {
      documentId = mapOrId;
      map = idOrMap;
    } else {
      documentId = idOrMap?.toString() ?? '';

      map = mapOrId is Map
          ? mapOrId
          : idOrMap is Map
              ? idOrMap
              : {};
    }

    return PlantModel(
      id: documentId,

      name: map['name']?.toString() ?? '',

      species: map['species']?.toString() ??
          map['type']?.toString() ??
          '',

      type: map['type']?.toString() ??
          map['species']?.toString() ??
          '',

      location: map['location']?.toString() ?? '',

      moisture: map['moisture']?.toString() ?? '0%',

      temperature: map['temperature']?.toString() ?? '0°C',

      status: map['status']?.toString() ?? 'Normal',

      lastUpdated: map['lastUpdated']?.toString() ?? 'Just now',

      soilPreference: map['soilPreference']?.toString() ?? '',

      lightRequirement: map['lightRequirement']?.toString() ?? '',

      wateringFrequency:
          map['wateringFrequency']?.toString() ?? '',

      // IMPORTANT:
      // Read the Cloudinary URL saved by PlantService.
      imageUrl: map['imageUrl']?.toString() ?? '',

      minTemp:
          double.tryParse(map['minTemp']?.toString() ?? '') ?? 0.0,

      maxTemp:
          double.tryParse(map['maxTemp']?.toString() ?? '') ?? 40.0,

      minHumidity:
          double.tryParse(map['minHumidity']?.toString() ?? '') ?? 0.0,

      maxHumidity:
          double.tryParse(map['maxHumidity']?.toString() ?? '') ?? 100.0,

      addedDate: _parseDate(map['addedDate']),

      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    // Handles ISO strings such as:
    // 2026-08-09T17:40:21.042
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // Handles Firebase ServerValue.timestamp
    // such as: 1786811481533
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'type': type,
      'location': location,
      'moisture': moisture,
      'temperature': temperature,
      'status': status,
      'lastUpdated': lastUpdated,
      'soilPreference': soilPreference,
      'lightRequirement': lightRequirement,
      'wateringFrequency': wateringFrequency,

      // Cloudinary image URL
      'imageUrl': imageUrl,

      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'addedDate': addedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}