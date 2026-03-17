import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LiveChatOverlay extends StatefulWidget {
  final String? channelName;

  const LiveChatOverlay({super.key, this.channelName});

  @override
  State<LiveChatOverlay> createState() => _LiveChatOverlayState();
}

class _LiveChatOverlayState extends State<LiveChatOverlay> {
  final TextEditingController _messageController = TextEditingController();

  CollectionReference<Map<String, dynamic>> _messagesRef(String channelName) {
    return FirebaseFirestore.instance
        .collection('liveStreams')
        .doc(channelName)
        .collection('messages');
  }

  Future<void> _sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _messageController.text.trim();
    final channelName = widget.channelName;

    if (uid == null ||
        text.isEmpty ||
        channelName == null ||
        channelName.isEmpty) {
      return;
    }

    await _messagesRef(channelName).add({
      'uid': uid,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelName = widget.channelName;
    if (channelName == null || channelName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesRef(
                channelName,
              ).orderBy('createdAt', descending: true).limit(20).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final message = data['message'] as String? ?? '';
                    final sender = data['uid'] as String? ?? 'user';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text:
                                  '${sender.substring(0, sender.length.clamp(0, 8))}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: message),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black45,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
