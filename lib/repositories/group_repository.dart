import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/group.dart';
import 'package:porno_social/models/group_member.dart';
import 'package:porno_social/models/post.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _groupsCollection = 'groups';
  static const String _membersCollection = 'members';
  static const String _postsCollection = 'posts';

  Future<String> createGroup(Group group) async {
    if (group.adminIds.isEmpty) {
      throw ArgumentError('Group must contain at least one adminId.');
    }

    final groupRef = await _firestore
        .collection(_groupsCollection)
        .add(group.toFirestore());

    final adminMember = GroupMember(
      uid: group.adminIds.first,
      role: GroupMemberRole.admin,
      joinedAt: DateTime.now(),
    );

    await groupRef
        .collection(_membersCollection)
        .doc(adminMember.uid)
        .set(adminMember.toFirestore());

    return groupRef.id;
  }

  Future<Group?> getGroupById(String groupId) async {
    final doc = await _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .get();
    if (!doc.exists) {
      return null;
    }

    return Group.fromFirestore(doc);
  }

  Stream<List<Group>> watchGroups({int limit = 30}) {
    return _firestore
        .collection(_groupsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Group.fromFirestore).toList());
  }

  Future<void> addMember({
    required String groupId,
    required String uid,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    final batch = _firestore.batch();
    final groupRef = _firestore.collection(_groupsCollection).doc(groupId);
    final memberRef = groupRef.collection(_membersCollection).doc(uid);

    batch.set(memberRef, {
      'role': role == GroupMemberRole.admin ? 'admin' : 'member',
      'joinedAt': Timestamp.now(),
    });

    batch.update(groupRef, {'memberCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> removeMember({
    required String groupId,
    required String uid,
  }) async {
    final batch = _firestore.batch();
    final groupRef = _firestore.collection(_groupsCollection).doc(groupId);
    final memberRef = groupRef.collection(_membersCollection).doc(uid);

    batch.delete(memberRef);
    batch.update(groupRef, {'memberCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<List<GroupMember>> getMembers(String groupId) async {
    final snapshot = await _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection(_membersCollection)
        .orderBy('joinedAt', descending: false)
        .get();

    return snapshot.docs.map(GroupMember.fromFirestore).toList();
  }

  Future<String> createGroupPost({
    required String groupId,
    required Post post,
  }) async {
    final docRef = await _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection(_postsCollection)
        .add(post.toFirestore());

    return docRef.id;
  }

  Stream<List<Post>> watchGroupPosts(String groupId, {int limit = 30}) {
    return _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Post.fromFirestore).toList());
  }
}
