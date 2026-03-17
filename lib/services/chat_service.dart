import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ChatService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String conversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String otherUid) {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) {
      return const Stream.empty();
    }

    final convId = conversationId(myUid, otherUid);
    return _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConversations() {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) {
      return const Stream.empty();
    }

    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String otherUid,
    required String text,
    String? mediaUrl,
    String type = 'text',
    bool isPaid = false,
    bool isUnlocked = true,
  }) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) {
      throw StateError('No authenticated user found.');
    }

    final convId = conversationId(myUid, otherUid);
    final convRef = _db.collection('conversations').doc(convId);

    await convRef.set({
      'participantIds': [myUid, otherUid],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'isPaidDm': false,
      'dmPrice': 0.0,
    }, SetOptions(merge: true));

    await convRef.collection('messages').add({
      'senderId': myUid,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'isPaid': isPaid,
      'isUnlocked': isUnlocked,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [myUid],
    });
  }

  Future<void> markRead(String otherUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) {
      throw StateError('No authenticated user found.');
    }

    final convId = conversationId(myUid, otherUid);
    final messagesSnap = await _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final batch = _db.batch();
    var updates = 0;

    for (final doc in messagesSnap.docs) {
      final data = doc.data();
      final readBy = List<String>.from(data['readBy'] ?? const <String>[]);
      if (!readBy.contains(myUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([myUid]),
        });
        updates++;
      }
    }

    if (updates > 0) {
      await batch.commit();
    }
  }
}
