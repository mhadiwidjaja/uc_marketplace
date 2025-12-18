class UserModel {
  final String uid;
  final String username;
  final String email;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
  });

  // Mengubah data dari Firebase (Map) ke Object Model
  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      uid: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
    );
  }

  // Mengubah Object Model ke Map untuk disimpan ke Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
    };
  }
}