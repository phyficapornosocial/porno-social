import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/repositories/post_repository.dart';
import 'package:porno_social/services/feed_service.dart';
import 'package:porno_social/models/post.dart';
import 'package:porno_social/providers/user_providers.dart';

export 'package:porno_social/models/post.dart';

// ============ Enhanced Repository & Service Providers ============

/// Post repository provider for dependency injection
final postRepositoryProvider = Provider((ref) {
  return PostRepository();
});

/// Feed service provider combining both repositories
final feedServiceProvider = Provider((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final postRepo = ref.watch(postRepositoryProvider);
  return FeedService(postRepository: postRepo, userRepository: userRepo);
});

// ============ Feed Providers ============

/// Get personalized feed based on user interests
final personalizedFeedProvider = FutureProvider.family<List<Post>, String>((
  ref,
  userId,
) async {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getPersonalizedFeed(userId);
});

/// Get trending creators
final trendingCreatorsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getTrendingCreators();
});

/// Get following feed
final followingFeedProvider =
    FutureProvider.family<
      List<Post>,
      (String userId, List<String> followedUserIds)
    >((ref, args) async {
      final (userId, followedUserIds) = args;
      final feedService = ref.watch(feedServiceProvider);
      return feedService.getFollowingFeed(userId, followedUserIds);
    });

/// Get enriched feed with author data
final enrichedFeedProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      userId,
    ) async {
      final feedService = ref.watch(feedServiceProvider);
      return feedService.getEnrichedFeed(userId);
    });

/// Global search across posts and users
final globalSearchProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
      final feedService = ref.watch(feedServiceProvider);
      return feedService.globalSearch(query);
    });

/// Get creator profile with posts
final creatorProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      final feedService = ref.watch(feedServiceProvider);
      return feedService.getCreatorProfile(userId);
    });

/// Get curated content by interests
final curatedContentProvider = FutureProvider.family<List<Post>, List<String>>((
  ref,
  interests,
) async {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getCuratedContent(interests);
});
