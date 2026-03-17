import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Color(0xFFe8000a), fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifs = snap.data?.docs ?? const [];
          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, color: Colors.grey, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final data = notifs[i].data();
              final isRead = data['isRead'] == true;
              return InkWell(
                onTap: () {
                  notifs[i].reference.update({'isRead': true});
                  _handleNotifTap(context, data);
                },
                child: Container(
                  color: isRead ? Colors.transparent : const Color(0xFF1A0000),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _NotifIcon(type: '${data['type'] ?? ''}'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['title'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${data['body'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _timeAgo(data['createdAt']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFe8000a),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotifTap(BuildContext context, Map<String, dynamic> data) {
    switch (data['type']) {
      case 'follow':
        final uid = data['fromUid'] as String?;
        if (uid != null && uid.isNotEmpty) {
          context.push('/profile/$uid');
        }
        break;
      case 'subscription':
        context.push('/dashboard/creator');
        break;
      default:
        break;
    }
  }

  Future<void> _markAllRead(String uid) async {
    final items = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in items.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  String _timeAgo(dynamic ts) {
    if (ts == null || ts is! Timestamp) return '';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _NotifIcon extends StatelessWidget {
  final String type;

  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    const icons = <String, IconData>{
      'follow': Icons.person_add,
      'like': Icons.favorite,
      'comment': Icons.comment,
      'message': Icons.message,
      'subscription': Icons.star,
      'live': Icons.live_tv,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFe8000a).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icons[type] ?? Icons.notifications,
        color: const Color(0xFFe8000a),
        size: 22,
      ),
    );
  }
}
