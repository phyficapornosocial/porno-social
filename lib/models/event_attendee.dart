import 'package:cloud_firestore/cloud_firestore.dart';

enum EventAttendanceStatus { going, maybe, notGoing }

class EventAttendee {
  final String uid;
  final EventAttendanceStatus status;
  final DateTime joinedAt;

  EventAttendee({
    required this.uid,
    required this.status,
    required this.joinedAt,
  });

  factory EventAttendee.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return EventAttendee(
      uid: doc.id,
      status: _parseStatus(data['status']),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': _statusToString(status),
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  EventAttendee copyWith({
    String? uid,
    EventAttendanceStatus? status,
    DateTime? joinedAt,
  }) {
    return EventAttendee(
      uid: uid ?? this.uid,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static EventAttendanceStatus _parseStatus(String? value) {
    switch (value) {
      case 'going':
        return EventAttendanceStatus.going;
      case 'maybe':
        return EventAttendanceStatus.maybe;
      case 'not_going':
      default:
        return EventAttendanceStatus.notGoing;
    }
  }

  static String _statusToString(EventAttendanceStatus status) {
    switch (status) {
      case EventAttendanceStatus.going:
        return 'going';
      case EventAttendanceStatus.maybe:
        return 'maybe';
      case EventAttendanceStatus.notGoing:
        return 'not_going';
    }
  }
}
