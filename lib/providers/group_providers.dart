import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/models/group.dart';
import 'package:porno_social/models/group_member.dart';
import 'package:porno_social/models/post.dart';
import 'package:porno_social/repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) {
  return GroupRepository();
});

final groupsProvider = StreamProvider<List<Group>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchGroups();
});

final groupByIdProvider = FutureProvider.family<Group?, String>((
  ref,
  groupId,
) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupById(groupId);
});

final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>((
  ref,
  groupId,
) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMembers(groupId);
});

final groupPostsProvider = StreamProvider.family<List<Post>, String>((
  ref,
  groupId,
) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchGroupPosts(groupId);
});

final addGroupMemberProvider =
    FutureProvider.family<void, AddGroupMemberParams>((ref, params) async {
      final repository = ref.watch(groupRepositoryProvider);
      await repository.addMember(
        groupId: params.groupId,
        uid: params.uid,
        role: params.role,
      );

      ref.invalidate(groupByIdProvider(params.groupId));
      ref.invalidate(groupMembersProvider(params.groupId));
      ref.invalidate(groupsProvider);
    });

final removeGroupMemberProvider =
    FutureProvider.family<void, RemoveGroupMemberParams>((ref, params) async {
      final repository = ref.watch(groupRepositoryProvider);
      await repository.removeMember(groupId: params.groupId, uid: params.uid);

      ref.invalidate(groupByIdProvider(params.groupId));
      ref.invalidate(groupMembersProvider(params.groupId));
      ref.invalidate(groupsProvider);
    });

class AddGroupMemberParams {
  final String groupId;
  final String uid;
  final GroupMemberRole role;

  AddGroupMemberParams({
    required this.groupId,
    required this.uid,
    this.role = GroupMemberRole.member,
  });
}

class RemoveGroupMemberParams {
  final String groupId;
  final String uid;

  RemoveGroupMemberParams({required this.groupId, required this.uid});
}
