import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { image, video, text }

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final bool isSubscribersOnly;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final List<String> tags;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.mediaUrls,
    required this.mediaType,
    required this.isSubscribersOnly,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.tags,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: _parseMediaType(data['mediaType']),
      isSubscribersOnly: data['isSubscribersOnly'] ?? false,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': _mediaTypeToString(mediaType),
      'isSubscribersOnly': isSubscribersOnly,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    List<String>? mediaUrls,
    MediaType? mediaType,
    bool? isSubscribersOnly,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      isSubscribersOnly: isSubscribersOnly ?? this.isSubscribersOnly,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'text':
      default:
        return MediaType.text;
    }
  }

  static String _mediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'image';
      case MediaType.video:
        return 'video';
      case MediaType.text:
        return 'text';
    }
  }
}
