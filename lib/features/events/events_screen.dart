import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porno_social/providers/event_providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events yet.'));
          }

          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              final startLabel = DateFormat(
                'EEE, MMM d • HH:mm',
              ).format(event.startAt);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: event.coverUrl.isNotEmpty
                      ? NetworkImage(event.coverUrl)
                      : null,
                  child: event.coverUrl.isEmpty
                      ? const Icon(Icons.event)
                      : null,
                ),
                title: Text(event.title),
                subtitle: Text(
                  '${event.city} • $startLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${event.attendeeCount}/${event.maxAttendees}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading events: $error'),
          ),
        ),
      ),
    );
  }
}
