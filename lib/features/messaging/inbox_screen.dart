import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:porno_social/features/messaging/chat_screen.dart';
import 'package:porno_social/services/chat_service.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in required to access inbox.')),
      );
    }

    final chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatService.getConversations(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final convs = snap.data!.docs;
          if (convs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: convs.length,
            itemBuilder: (context, i) {
              final data = convs[i].data();
              final ids = List<String>.from(
                data['participantIds'] ?? const <String>[],
              );
              final otherUid = ids.firstWhere(
                (id) => id != myUid,
                orElse: () => '',
              );

              if (otherUid.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final user = userSnap.data!.data() ?? <String, dynamic>{};
                  final avatar = (user['avatarUrl'] ?? '').toString();
                  final displayName = (user['displayName'] ?? '').toString();
                  final lastMessage = (data['lastMessage'] ?? '').toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUid: otherUid,
                            otherName: displayName,
                            otherAvatar: avatar,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
