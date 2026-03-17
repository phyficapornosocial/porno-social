import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupMemberRole { admin, member }

class GroupMember {
  final String uid;
  final GroupMemberRole role;
  final DateTime joinedAt;

  GroupMember({required this.uid, required this.role, required this.joinedAt});

  factory GroupMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupMember(
      uid: doc.id,
      role: _parseRole(data['role']),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': _roleToString(role),
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  GroupMember copyWith({
    String? uid,
    GroupMemberRole? role,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static GroupMemberRole _parseRole(String? value) {
    switch (value) {
      case 'admin':
        return GroupMemberRole.admin;
      case 'member':
      default:
        return GroupMemberRole.member;
    }
  }

  static String _roleToString(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.admin:
        return 'admin';
      case GroupMemberRole.member:
        return 'member';
    }
  }
}
