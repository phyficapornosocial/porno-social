import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/models/story.dart';

final storiesProvider = StreamProvider<List<Story>>((ref) {
  return FirebaseFirestore.instance
      .collection('stories')
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
      });
});

final storyByIdProvider = FutureProvider.family<Story?, String>((
  ref,
  storyId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .get();

    if (!doc.exists) return null;
    return Story.fromFirestore(doc);
  } catch (e) {
    rethrow;
  }
});

final storiesRepositoryProvider = Provider((ref) {
  return StoriesRepository(FirebaseFirestore.instance);
});

class StoriesRepository {
  final FirebaseFirestore _firestore;

  StoriesRepository(this._firestore);

  Stream<List<Story>> getStoriesStream() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
        });
  }

  Future<Story?> getStoryById(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      if (!doc.exists) return null;
      return Story.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addViewer(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewerIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadStory({
    required String mediaUrl,
    required String mediaType,
    required String authorId,
    required String authorName,
    required String authorAvatar,
  }) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      await _firestore.collection('stories').add({
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewerIds': <String>[],
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpiredStories() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
