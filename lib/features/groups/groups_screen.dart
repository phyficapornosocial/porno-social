import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/providers/group_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text('No groups yet. Create one from your backend/admin.'),
            );
          }

          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  backgroundImage: group.coverUrl.isNotEmpty
                      ? NetworkImage(group.coverUrl)
                      : null,
                  child: group.coverUrl.isEmpty
                      ? const Icon(Icons.groups)
                      : null,
                ),
                title: Text(group.name),
                subtitle: Text(
                  group.description.isNotEmpty
                      ? group.description
                      : 'No description',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${group.memberCount}'),
                    const Text('members', style: TextStyle(fontSize: 11)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading groups: $error'),
          ),
        ),
      ),
    );
  }
}
