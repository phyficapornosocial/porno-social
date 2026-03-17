import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/models/short.dart';

final shortsProvider = StreamProvider<List<Short>>((ref) {
  return FirebaseFirestore.instance
      .collection('shorts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
      });
});

final shortByIdProvider = FutureProvider.family<Short?, String>((
  ref,
  shortId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('shorts')
        .doc(shortId)
        .get();

    if (!doc.exists) return null;
    return Short.fromFirestore(doc);
  } catch (e) {
    rethrow;
  }
});

final shortsRepositoryProvider = Provider((ref) {
  return ShortsRepository(FirebaseFirestore.instance);
});

class ShortsRepository {
  final FirebaseFirestore _firestore;

  ShortsRepository(this._firestore);

  Stream<List<Short>> getShortsStream() {
    return _firestore
        .collection('shorts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
        });
  }

  Future<void> incrementViewCount(String shortId) async {
    try {
      await _firestore.collection('shorts').doc(shortId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeShort(String shortId) async {
    try {
      await _firestore.collection('shorts').doc(shortId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlikeShort(String shortId) async {
    try {
      await _firestore.collection('shorts').doc(shortId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareShort(String shortId) async {
    try {
      await _firestore.collection('shorts').doc(shortId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }
}
