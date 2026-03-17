import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/models/event.dart';
import 'package:porno_social/models/event_attendee.dart';
import 'package:porno_social/repositories/event_repository.dart';

final eventRepositoryProvider = Provider((ref) {
  return EventRepository();
});

final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.watchUpcomingEvents();
});

final eventByIdProvider = FutureProvider.family<Event?, String>((
  ref,
  eventId,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventById(eventId);
});

final eventAttendeesProvider =
    FutureProvider.family<List<EventAttendee>, String>((ref, eventId) async {
      final repository = ref.watch(eventRepositoryProvider);
      return repository.getAttendees(eventId);
    });

final setAttendanceProvider = FutureProvider.family<void, SetAttendanceParams>((
  ref,
  params,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  await repository.setAttendance(
    eventId: params.eventId,
    uid: params.uid,
    status: params.status,
  );

  ref.invalidate(eventByIdProvider(params.eventId));
  ref.invalidate(eventAttendeesProvider(params.eventId));
  ref.invalidate(upcomingEventsProvider);
});

class SetAttendanceParams {
  final String eventId;
  final String uid;
  final EventAttendanceStatus status;

  SetAttendanceParams({
    required this.eventId,
    required this.uid,
    required this.status,
  });
}
