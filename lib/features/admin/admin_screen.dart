import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          title: const Text(
            'Admin Panel',
            style: TextStyle(color: Color(0xFFe8000a)),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFe8000a),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Reports'),
              Tab(text: 'Verifications'),
              Tab(text: 'Users'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ReportsTab(), _VerificationsTab(), _UsersTab()],
        ),
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return const Center(
            child: Text(
              'Failed to load reports',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final reports = snap.data?.docs ?? const [];
        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'No pending reports',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final doc = reports[i];
            final data = doc.data();
            return Card(
              color: const Color(0xFF111111),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFe8000a,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${data['targetType'] ?? ''}',
                            style: const TextStyle(
                              color: Color(0xFFe8000a),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${data['reason'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(data['createdAt']),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Target ID: ${data['targetId'] ?? ''}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if ((data['description'] as String?)?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${data['description']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                            ),
                            onPressed: () => _dismiss(doc.id),
                            child: const Text(
                              'Dismiss',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe8000a),
                            ),
                            onPressed: () =>
                                _showActionMenu(context, doc.id, data),
                            child: const Text(
                              'Take Action',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _dismiss(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
          'status': 'dismissed',
          'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _showActionMenu(
    BuildContext context,
    String reportId,
    Map<String, dynamic> data,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Take Action', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFe8000a)),
              title: const Text(
                'Delete reported item',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                await _deleteTarget(data);
                await FirebaseFirestore.instance
                    .collection('reports')
                    .doc(reportId)
                    .update({
                      'status': 'actioned',
                      'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
                      'reviewedAt': FieldValue.serverTimestamp(),
                    });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text(
                'Ban target user',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final targetUid = await _resolveTargetUid(data);
                if (targetUid != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUid)
                      .set({
                        'isBanned': true,
                        'bannedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                }
                await FirebaseFirestore.instance
                    .collection('reports')
                    .doc(reportId)
                    .update({
                      'status': 'actioned',
                      'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
                      'reviewedAt': FieldValue.serverTimestamp(),
                    });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTarget(Map<String, dynamic> data) async {
    final type = '${data['targetType'] ?? ''}';
    final id = '${data['targetId'] ?? ''}';
    final collection = switch (type) {
      'post' => 'posts',
      'story' => 'stories',
      'user' => 'users',
      'comment' => 'comments',
      _ => '',
    };
    if (collection.isEmpty || id.isEmpty) return;
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }

  Future<String?> _resolveTargetUid(Map<String, dynamic> data) async {
    final type = '${data['targetType'] ?? ''}';
    final id = '${data['targetId'] ?? ''}';

    if (type == 'user') return id;
    if (type == 'post') {
      final post = await FirebaseFirestore.instance
          .collection('posts')
          .doc(id)
          .get();
      return post.data()?['authorId'] as String?;
    }

    return null;
  }

  String _timeAgo(dynamic ts) {
    if (ts == null || ts is! Timestamp) return '';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _VerificationsTab extends StatelessWidget {
  const _VerificationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('private')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending verification requests',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final uid = docs[i].reference.parent.parent?.id;
            if (uid == null) return const SizedBox.shrink();
            return Card(
              color: const Color(0xFF111111),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(
                  'User: $uid',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                subtitle: Text(
                  '${data['email'] ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approve(uid, docs[i].reference),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Color(0xFFe8000a)),
                      onPressed: () => _reject(docs[i].reference),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approve(
    String uid,
    DocumentReference<Map<String, dynamic>> privateRef,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(privateRef, {'verificationStatus': 'approved'});
    batch.set(
      FirebaseFirestore.instance.collection('users').doc(uid),
      {'isVerified': true},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> _reject(
    DocumentReference<Map<String, dynamic>> privateRef,
  ) async {
    await privateRef.update({'verificationStatus': 'rejected'});
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? const [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final uid = docs[i].id;
            final avatar = (data['avatarUrl'] ?? '') as String;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                backgroundColor: const Color(0xFF333333),
                child: avatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              title: Text(
                '${data['displayName'] ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '@${data['username'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data['isVerified'] == true)
                    const Icon(
                      Icons.verified,
                      color: Color(0xFFe8000a),
                      size: 18,
                    ),
                  if (data['isBanned'] == true)
                    const Icon(Icons.block, color: Colors.red, size: 18),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1E1E1E),
                    onSelected: (action) => _handleUserAction(action, uid),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'ban',
                        child: Text(
                          'Ban user',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'unban',
                        child: Text(
                          'Unban',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'verify',
                        child: Text(
                          'Force verify',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleUserAction(String action, String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    switch (action) {
      case 'ban':
        await ref.set({'isBanned': true}, SetOptions(merge: true));
        break;
      case 'unban':
        await ref.set({'isBanned': false}, SetOptions(merge: true));
        break;
      case 'verify':
        await ref.set({'isVerified': true}, SetOptions(merge: true));
        break;
    }
  }
}
