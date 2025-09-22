import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final String imageUrl;
  final bool isAnonymous;
  final DateTime createdAt;
  final int likesCount;
  final int sharesCount;
  final int commentsCount;
  final String authorName;
  final String userName;
  final String profilePhotoUrl;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl = '',
    required this.isAnonymous,
    required this.createdAt,
    this.likesCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.authorName = '',
    this.userName = '',
    this.profilePhotoUrl = '',
    this.isLiked = false,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'sharesCount': sharesCount,
      'commentsCount': commentsCount,
      'authorName': authorName,
      'userName': userName,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  // Create from Firestore document
  static PostModel fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      userId: (map['userId'] ?? map['uid'] ?? map['authorId'] ?? '') as String,
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      authorName: (map['authorName'] ?? map['userName'] ?? '') as String,
      userName: (map['userName'] ?? map['authorName'] ?? '') as String,
      profilePhotoUrl:
          (map['profilePhotoUrl'] ?? map['photoURL'] ?? map['photoUrl'] ?? '')
              as String,
      isLiked: map['isLiked'] ?? false,
    );
  }

  // Copy with updated values
  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    int? likesCount,
    int? sharesCount,
    int? commentsCount,
    String? authorName,
    String? userName,
    String? profilePhotoUrl,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      authorName: authorName ?? this.authorName,
      userName: userName ?? this.userName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

// Like model for subcollection
class LikeModel {
  final String id;
  final String userId;
  final DateTime createdAt;

  LikeModel({required this.id, required this.userId, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'createdAt': Timestamp.fromDate(createdAt)};
  }

  static LikeModel fromMap(Map<String, dynamic> map, String documentId) {
    return LikeModel(
      id: documentId,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Comment model for subcollection
class CommentModel {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final int likesCount;

  CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
    };
  }

  static CommentModel fromMap(Map<String, dynamic> map, String documentId) {
    return CommentModel(
      id: documentId,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
    );
  }
}

// Share model for subcollection
class ShareModel {
  final String id;
  final String userId;
  final String sharedTo;
  final DateTime createdAt;

  ShareModel({
    required this.id,
    required this.userId,
    required this.sharedTo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sharedTo': sharedTo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ShareModel fromMap(Map<String, dynamic> map, String documentId) {
    return ShareModel(
      id: documentId,
      userId: map['userId'] ?? '',
      sharedTo: map['sharedTo'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
