import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/post.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _postsCollection = 'posts';
  static const String _likesCollection = 'likes';
  static const String _commentsCollection = 'comments';

  // ============ Post CRUD ============

  /// Create a new post
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String content,
    required List<String> mediaUrls,
    required MediaType mediaType,
    bool isSubscribersOnly = false,
    required List<String> tags,
  }) async {
    try {
      final now = DateTime.now();
      final postData = {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'mediaUrls': mediaUrls,
        'mediaType': _mediaTypeToString(mediaType),
        'isSubscribersOnly': isSubscribersOnly,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'tags': tags,
      };

      final docRef = await _firestore
          .collection(_postsCollection)
          .add(postData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .get();
      if (!doc.exists) return null;
      return Post.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all posts by a specific author
  Future<List<Post>> getPostsByAuthor(String authorId) async {
    try {
      final query = await _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete post document
      await _firestore.collection(_postsCollection).doc(postId).delete();

      // Clean up likes and comments within subcollections
      final likesSnap = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .get();

      for (var doc in likesSnap.docs) {
        await doc.reference.delete();
      }

      final commentsSnap = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .get();

      for (var doc in commentsSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update post content (text only, minimal updates)
  Future<void> updatePost(
    String postId, {
    required String content,
    required List<String> tags,
  }) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'content': content,
        'tags': tags,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ============ Feed Queries ============

  /// Get main feed (posts sorted by recency)
  Future<List<Post>> getMainFeed({int limit = 20}) async {
    try {
      final query = await _firestore
          .collection(_postsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get paginated feed with cursor support
  Future<List<Post>> getMainFeedPaginated({
    required int limit,
    DocumentSnapshot? startAfterDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_postsCollection)
          .orderBy('createdAt', descending: true);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final result = await query.limit(limit).get();
      return result.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get feed for followed creators
  Future<List<Post>> getFollowingFeed(
    List<String> followedUserIds, {
    int limit = 20,
  }) async {
    try {
      if (followedUserIds.isEmpty) return [];

      final query = await _firestore
          .collection(_postsCollection)
          .where('authorId', whereIn: followedUserIds)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search posts by tags
  Future<List<Post>> searchByTags(List<String> tags, {int limit = 50}) async {
    try {
      if (tags.isEmpty) return [];

      final query = await _firestore
          .collection(_postsCollection)
          .where('tags', arrayContainsAny: tags)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search posts by content (basic substring search)
  Future<List<Post>> searchByContent(String query, {int limit = 50}) async {
    try {
      final results = await _firestore
          .collection(_postsCollection)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '$query\u{FFFF}')
          .limit(limit)
          .get();

      return results.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get trending posts (by like count)
  Future<List<Post>> getTrendingPosts({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection(_postsCollection)
          .orderBy('likeCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ============ Like Management ============

  /// Check if user has liked a post
  Future<bool> hasUserLiked(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  /// Add like to a post
  Future<void> likePost(String postId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Add like document
      final likeRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .doc(userId);

      batch.set(likeRef, {'likedAt': Timestamp.now()});

      // Increment like count
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      batch.update(postRef, {'likeCount': FieldValue.increment(1)});

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove like from a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Remove like document
      final likeRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .doc(userId);

      batch.delete(likeRef);

      // Decrement like count
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      batch.update(postRef, {'likeCount': FieldValue.increment(-1)});

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users who liked a post
  Future<List<String>> getPostLikes(String postId) async {
    try {
      final query = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .get();

      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ============ Comment Management ============

  /// Add comment to a post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String authorAvatar,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final commentData = {
        'userId': userId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'createdAt': Timestamp.fromDate(now),
        'likeCount': 0,
      };

      final docRef = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .add(commentData);

      // Increment comment count on post
      await _firestore.collection(_postsCollection).doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(
    String postId, {
    int limit = 100,
  }) async {
    try {
      final query = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final batch = _firestore.batch();

      // Delete comment
      final commentRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .doc(commentId);

      batch.delete(commentRef);

      // Decrement comment count
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      batch.update(postRef, {'commentCount': FieldValue.increment(-1)});

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // ============ Helper Methods ============

  static String _mediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'image';
      case MediaType.video:
        return 'video';
      case MediaType.text:
        return 'text';
    }
  }

  /// Get a Firestore Query reference for custom queries
  Query getPostsQuery() => _firestore.collection(_postsCollection);
}
