import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final bool isCreator;
  final bool isVerified;
  final double subscriptionPrice;
  final int subscriberCount;
  final DateTime createdAt;
  final GeoPoint? location;
  final List<String> interests;

  User({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.isCreator,
    required this.isVerified,
    required this.subscriptionPrice,
    required this.subscriberCount,
    required this.createdAt,
    this.location,
    required this.interests,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isCreator: data['isCreator'] ?? false,
      isVerified: data['isVerified'] ?? false,
      subscriptionPrice: (data['subscriptionPrice'] ?? 0).toDouble(),
      subscriberCount: data['subscriberCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      location: data['location'],
      interests: List<String>.from(data['interests'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isCreator': isCreator,
      'isVerified': isVerified,
      'subscriptionPrice': subscriptionPrice,
      'subscriberCount': subscriberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'interests': interests,
    };
  }

  User copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isCreator,
    bool? isVerified,
    double? subscriptionPrice,
    int? subscriberCount,
    DateTime? createdAt,
    GeoPoint? location,
    List<String>? interests,
  }) {
    return User(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCreator: isCreator ?? this.isCreator,
      isVerified: isVerified ?? this.isVerified,
      subscriptionPrice: subscriptionPrice ?? this.subscriptionPrice,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      interests: interests ?? this.interests,
    );
  }
}
