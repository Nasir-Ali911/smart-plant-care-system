class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  // Convert Firestore Document to UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt']).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
    };
  }
}