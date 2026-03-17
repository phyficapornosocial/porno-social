import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/user.dart';
import 'package:porno_social/models/user_private.dart';
import 'package:porno_social/repositories/user_repository.dart';
import 'package:porno_social/providers/auth_providers.dart';

// User repository provider
final userRepositoryProvider = Provider((ref) {
  return UserRepository();
});

// Watch current user's profile
final currentUserProfileProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(userId);
});

// Watch current user's private data
final currentUserPrivateDataProvider = FutureProvider<UserPrivate?>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserPrivateData(userId);
});

// Get user profile by ID
final userProfileProvider = FutureProvider.family<User?, String>((
  ref,
  userId,
) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(userId);
});

// Get user by username
final userByUsernameProvider = FutureProvider.family<User?, String>((
  ref,
  username,
) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserByUsername(username);
});

// Update user profile notifier
final updateUserProfileProvider =
    FutureProvider.family<void, UpdateUserProfileParams>((ref, params) async {
      final userRepository = ref.watch(userRepositoryProvider);
      await userRepository.updateUserProfile(
        uid: params.uid,
        displayName: params.displayName,
        bio: params.bio,
        avatarUrl: params.avatarUrl,
        interests: params.interests,
        location: params.location,
      );
      // Invalidate the user profile cache to refetch fresh data
      ref.invalidate(userProfileProvider(params.uid));
      ref.invalidate(currentUserProfileProvider);
    });

// Become creator notifier
final becomeCreatorProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final userRepository = ref.watch(userRepositoryProvider);
  await userRepository.becomeCreator(uid);
  ref.invalidate(userProfileProvider(uid));
  ref.invalidate(currentUserProfileProvider);
});

// Set subscription price notifier
final setSubscriptionPriceProvider =
    FutureProvider.family<void, SetSubscriptionPriceParams>((
      ref,
      params,
    ) async {
      final userRepository = ref.watch(userRepositoryProvider);
      await userRepository.setSubscriptionPrice(params.uid, params.price);
      ref.invalidate(userProfileProvider(params.uid));
      ref.invalidate(currentUserProfileProvider);
    });

// Search users by username
final searchUsersByUsernameProvider = FutureProvider.family<List<User>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final userRepository = ref.watch(userRepositoryProvider);
    return userRepository.searchUsersByUsername(query);
  },
);

// Search creators by interest
final searchCreatorsByInterestProvider =
    FutureProvider.family<List<User>, String>((ref, interest) async {
      if (interest.isEmpty) return [];
      final userRepository = ref.watch(userRepositoryProvider);
      return userRepository.searchCreatorsByInterest(interest);
    });

// Get nearby creators
final nearbyCreatorsProvider = FutureProvider.family<List<User>, GeoPoint>((
  ref,
  center,
) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getNearbyCreators(center: center);
});

// Delete user account notifier
final deleteUserAccountProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final userRepository = ref.watch(userRepositoryProvider);
  await userRepository.deleteUser(uid);
  ref.invalidate(currentUserProfileProvider);
});

// Data classes for parameters
class UpdateUserProfileParams {
  final String uid;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final List<String>? interests;
  final GeoPoint? location;

  UpdateUserProfileParams({
    required this.uid,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.interests,
    this.location,
  });
}

class SetSubscriptionPriceParams {
  final String uid;
  final double price;

  SetSubscriptionPriceParams({required this.uid, required this.price});
}
