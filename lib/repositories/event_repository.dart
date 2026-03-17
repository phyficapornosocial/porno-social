import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/event.dart';
import 'package:porno_social/models/event_attendee.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _eventsCollection = 'events';
  static const String _attendeesCollection = 'attendees';

  Future<String> createEvent(Event event) async {
    final docRef = await _firestore
        .collection(_eventsCollection)
        .add(event.toFirestore());
    return docRef.id;
  }

  Future<Event?> getEventById(String eventId) async {
    final doc = await _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .get();
    if (!doc.exists) {
      return null;
    }

    return Event.fromFirestore(doc);
  }

  Stream<List<Event>> watchUpcomingEvents({int limit = 50}) {
    return _firestore
        .collection(_eventsCollection)
        .where('endAt', isGreaterThan: Timestamp.now())
        .orderBy('endAt')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
  }

  Future<void> setAttendance({
    required String eventId,
    required String uid,
    required EventAttendanceStatus status,
  }) async {
    final batch = _firestore.batch();
    final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
    final attendeeRef = eventRef.collection(_attendeesCollection).doc(uid);

    final existing = await attendeeRef.get();

    batch.set(attendeeRef, {
      'status': _statusToFirestore(status),
      'joinedAt': Timestamp.now(),
    });

    if (!existing.exists && status != EventAttendanceStatus.notGoing) {
      batch.update(eventRef, {'attendeeCount': FieldValue.increment(1)});
    }

    if (existing.exists && status == EventAttendanceStatus.notGoing) {
      batch.update(eventRef, {'attendeeCount': FieldValue.increment(-1)});
    }

    await batch.commit();
  }

  Future<List<EventAttendee>> getAttendees(String eventId) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .collection(_attendeesCollection)
        .get();

    return snapshot.docs.map(EventAttendee.fromFirestore).toList();
  }

  String _statusToFirestore(EventAttendanceStatus status) {
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
