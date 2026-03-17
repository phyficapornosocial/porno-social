import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final GeoPoint location;
  final String address;
  final String city;
  final DateTime startAt;
  final DateTime endAt;
  final bool isPrivate;
  final int maxAttendees;
  final int attendeeCount;
  final String coverUrl;
  final List<String> tags;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.location,
    required this.address,
    required this.city,
    required this.startAt,
    required this.endAt,
    required this.isPrivate,
    required this.maxAttendees,
    required this.attendeeCount,
    required this.coverUrl,
    required this.tags,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      hostId: data['hostId'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      startAt: data['startAt'] != null
          ? (data['startAt'] as Timestamp).toDate()
          : DateTime.now(),
      endAt: data['endAt'] != null
          ? (data['endAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPrivate: data['isPrivate'] ?? false,
      maxAttendees: data['maxAttendees'] ?? 0,
      attendeeCount: data['attendeeCount'] ?? 0,
      coverUrl: data['coverUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'hostId': hostId,
      'location': location,
      'address': address,
      'city': city,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'isPrivate': isPrivate,
      'maxAttendees': maxAttendees,
      'attendeeCount': attendeeCount,
      'coverUrl': coverUrl,
      'tags': tags,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? hostId,
    GeoPoint? location,
    String? address,
    String? city,
    DateTime? startAt,
    DateTime? endAt,
    bool? isPrivate,
    int? maxAttendees,
    int? attendeeCount,
    String? coverUrl,
    List<String>? tags,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isPrivate: isPrivate ?? this.isPrivate,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      coverUrl: coverUrl ?? this.coverUrl,
      tags: tags ?? this.tags,
    );
  }
}
