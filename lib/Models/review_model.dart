class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String title;
  final String reviewText;
  final String? imageUrl;
  final bool isAnonymous;
  final int timestamp;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.title,
    required this.reviewText,
    this.imageUrl,
    required this.isAnonymous,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'title': title,
      'reviewText': reviewText,
      'imageUrl': imageUrl,
      'isAnonymous': isAnonymous,
      'timestamp': timestamp,
    };
  }

  factory ReviewModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      userAvatarUrl: map['userAvatarUrl'],
      rating: map['rating'] ?? 0,
      title: map['title'] ?? '',
      reviewText: map['reviewText'] ?? '',
      imageUrl: map['imageUrl'],
      isAnonymous: map['isAnonymous'] ?? false,
      timestamp: map['timestamp'] ?? 0,
    );
  }
}
