class UserModel {
  final String uid;
  final String username;
  final String email;
  final String phoneNumber; // Wajib diisi
  final String? profileImageUrl; // Opsional, bisa null jika belum upload

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      uid: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
    };
  }
}