import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/user.dart';
import 'package:porno_social/models/user_private.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _privateCollection = 'private';

  // ============ Public User Data ============

  Future<User> createUser({
    required String uid,
    required String username,
    required String displayName,
    required String email,
    required DateTime dateOfBirth,
  }) async {
    final now = DateTime.now();
    final user = User(
      uid: uid,
      username: username,
      displayName: displayName,
      bio: '',
      avatarUrl: '',
      isCreator: false,
      isVerified: false,
      subscriptionPrice: 0.0,
      subscriberCount: 0,
      createdAt: now,
      location: null,
      interests: [],
    );

    // Create public profile
    await _firestore
        .collection(_usersCollection)
        .doc(uid)
        .set(user.toFirestore());

    // Create private data
    final userPrivate = UserPrivate(
      uid: uid,
      email: email,
      dateOfBirth: dateOfBirth,
      verificationStatus: 'pending',
    );

    await _firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_privateCollection)
        .doc(uid)
        .set(userPrivate.toFirestore());

    return user;
  }

  Future<User?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return User.fromFirestore(query.docs.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(String uid, User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? interests,
    GeoPoint? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (interests != null) updates['interests'] = interests;
      if (location != null) updates['location'] = location;

      await _firestore.collection(_usersCollection).doc(uid).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Delete private data first
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_privateCollection)
          .doc(uid)
          .delete();

      // Delete public profile
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ============ Private User Data ============

  Future<UserPrivate?> getUserPrivateData(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_privateCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      return UserPrivate.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserPrivateData(
    String uid,
    UserPrivate userPrivate,
  ) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_privateCollection)
          .doc(uid)
          .update(userPrivate.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVerificationStatus(String uid, String status) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_privateCollection)
          .doc(uid)
          .update({'verificationStatus': status});
    } catch (e) {
      rethrow;
    }
  }

  // ============ Search & Discovery ============

  Future<List<User>> searchUsersByUsername(String query) async {
    try {
      final results = await _firestore
          .collection(_usersCollection)
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\u{FFFF}')
          .limit(20)
          .get();

      return results.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> searchCreatorsByInterest(String interest) async {
    try {
      final results = await _firestore
          .collection(_usersCollection)
          .where('isCreator', isEqualTo: true)
          .where('interests', arrayContains: interest)
          .limit(50)
          .get();

      return results.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getNearbyCreators({
    required GeoPoint center,
    double radiusInKm = 50,
  }) async {
    try {
      // Note: Firestore doesn't have built-in geospatial queries
      // This is a simplified implementation that gets all creators
      // For production, consider using Firestore's geohashing or Cloud Functions
      final results = await _firestore
          .collection(_usersCollection)
          .where('isCreator', isEqualTo: true)
          .where('location', isNotEqualTo: null)
          .limit(100)
          .get();

      return results.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ============ Creator Management ============

  Future<void> becomeCreator(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'isCreator': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setSubscriptionPrice(String uid, double price) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'subscriptionPrice': price,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementSubscriberCount(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'subscriberCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decrementSubscriberCount(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'subscriberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }
}
