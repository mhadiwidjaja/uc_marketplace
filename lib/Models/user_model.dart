class UserModel {
  final String uid;
  final String username;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final int walletBalance; // Field baru

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    this.walletBalance = 0, // Default 0
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      uid: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      walletBalance: map['walletBalance'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'walletBalance': walletBalance,
    };
  }
}