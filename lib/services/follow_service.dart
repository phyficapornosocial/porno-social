import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FollowService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<void> follow(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || myUid == targetUid) return;

    final batch = _db.batch();

    batch.set(
      _db
          .collection('followers')
          .doc(myUid)
          .collection('following')
          .doc(targetUid),
      {'followedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    batch.set(
      _db
          .collection('followers')
          .doc(targetUid)
          .collection('followers')
          .doc(myUid),
      {'followedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    batch.set(_db.collection('users').doc(targetUid), {
      'followerCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();

    await _db.collection('notifications_queue').add({
      'type': 'follow',
      'targetUid': targetUid,
      'fromUid': myUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollow(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || myUid == targetUid) return;

    final batch = _db.batch();

    batch.delete(
      _db
          .collection('followers')
          .doc(myUid)
          .collection('following')
          .doc(targetUid),
    );
    batch.delete(
      _db
          .collection('followers')
          .doc(targetUid)
          .collection('followers')
          .doc(myUid),
    );

    batch.set(_db.collection('users').doc(targetUid), {
      'followerCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));
    batch.set(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<bool> isFollowing(String targetUid) {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return const Stream<bool>.empty();

    return _db
        .collection('followers')
        .doc(myUid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
