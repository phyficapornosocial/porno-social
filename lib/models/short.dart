import 'package:cloud_firestore/cloud_firestore.dart';

class Short {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String videoUrl;
  final String? caption;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final DateTime createdAt;
  final List<String> tags;
  final bool isSubscribersOnly;

  Short({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.videoUrl,
    this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.viewCount,
    required this.createdAt,
    required this.tags,
    required this.isSubscribersOnly,
  });

  factory Short.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Short(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      caption: data['caption'],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      isSubscribersOnly: data['isSubscribersOnly'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'videoUrl': videoUrl,
      'caption': caption,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'createdAt': createdAt,
      'tags': tags,
      'isSubscribersOnly': isSubscribersOnly,
    };
  }
}
