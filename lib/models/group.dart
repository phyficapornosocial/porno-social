import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final bool isPrivate;
  final int memberCount;
  final List<String> adminIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.isPrivate,
    required this.memberCount,
    required this.adminIds,
    required this.createdAt,
  });

  factory Group.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      memberCount: data['memberCount'] ?? 0,
      adminIds: List<String>.from(data['adminIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'isPrivate': isPrivate,
      'memberCount': memberCount,
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    bool? isPrivate,
    int? memberCount,
    List<String>? adminIds,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      memberCount: memberCount ?? this.memberCount,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
