import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime expiresAt;
  final List<String> viewerIds;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.mediaUrl,
    required this.mediaType,
    required this.expiresAt,
    required this.viewerIds,
    required this.createdAt,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewerIds: List<String>.from(data['viewerIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewerIds': viewerIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get hasExpired => DateTime.now().isAfter(expiresAt);

  bool get isViewed => viewerIds.isNotEmpty;

  Story copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? mediaUrl,
    String? mediaType,
    DateTime? expiresAt,
    List<String>? viewerIds,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerIds: viewerIds ?? this.viewerIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
