import 'package:porno_social/models/post.dart';
import 'package:porno_social/repositories/post_repository.dart';
import 'package:porno_social/repositories/user_repository.dart';

/// Advanced feed service combining posts and user operations
class FeedService {
  final PostRepository _postRepository;
  final UserRepository _userRepository;

  FeedService({
    required PostRepository postRepository,
    required UserRepository userRepository,
  }) : _postRepository = postRepository,
       _userRepository = userRepository;

  /// Get personalized feed for a user based on their interests
  Future<List<Post>> getPersonalizedFeed(String userId) async {
    try {
      // Get user's interests
      final user = await _userRepository.getUserById(userId);
      if (user == null) return [];

      // Get posts matching user's interests
      if (user.interests.isEmpty) {
        // If no interests, return trending posts
        return _postRepository.getTrendingPosts();
      }

      return _postRepository.searchByTags(user.interests);
    } catch (e) {
      rethrow;
    }
  }

  /// Get feed from followed creators
  Future<List<Post>> getFollowingFeed(
    String userId,
    List<String> followedUserIds,
  ) async {
    try {
      if (followedUserIds.isEmpty) {
        return _postRepository.getMainFeed();
      }

      return _postRepository.getFollowingFeed(followedUserIds);
    } catch (e) {
      rethrow;
    }
  }

  /// Get feed with enriched author data
  Future<List<Map<String, dynamic>>> getEnrichedFeed(String userId) async {
    try {
      final posts = await _postRepository.getMainFeed();
      final enrichedPosts = <Map<String, dynamic>>[];

      for (final post in posts) {
        final author = await _userRepository.getUserById(post.authorId);
        enrichedPosts.add({
          'post': post,
          'author': author,
          'hasLiked': await _postRepository.hasUserLiked(post.id, userId),
        });
      }

      return enrichedPosts;
    } catch (e) {
      rethrow;
    }
  }

  /// Search across posts and users
  Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final posts = await _postRepository.searchByContent(query);
      final users = await _userRepository.searchUsersByUsername(query);

      return {'posts': posts, 'users': users};
    } catch (e) {
      rethrow;
    }
  }

  /// Get creator profile with their posts
  Future<Map<String, dynamic>> getCreatorProfile(String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) throw Exception('User not found');

      final posts = await _postRepository.getPostsByAuthor(userId);
      final isCreator = user.isCreator;

      return {
        'user': user,
        'posts': posts,
        'postCount': posts.length,
        'isCreator': isCreator,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get trending creators (by subscriber count)
  Future<List<Map<String, dynamic>>> getTrendingCreators({
    int limit = 20,
  }) async {
    try {
      final trendingPosts = await _postRepository.getTrendingPosts(
        limit: limit * 2,
      );
      final creatorIds = <String>{};

      for (final post in trendingPosts) {
        creatorIds.add(post.authorId);
        if (creatorIds.length >= limit) break;
      }

      final creators = <Map<String, dynamic>>[];
      for (final creatorId in creatorIds) {
        final user = await _userRepository.getUserById(creatorId);
        if (user != null && user.isCreator) {
          final postCount = (await _postRepository.getPostsByAuthor(
            creatorId,
          )).length;
          creators.add({'user': user, 'postCount': postCount});
        }
      }

      return creators;
    } catch (e) {
      rethrow;
    }
  }

  /// Get curated content by interests (similar to recommended for you)
  Future<List<Post>> getCuratedContent(
    List<String> interests, {
    int limit = 50,
  }) async {
    try {
      if (interests.isEmpty) {
        return _postRepository.getTrendingPosts(limit: limit);
      }

      return _postRepository.searchByTags(interests, limit: limit);
    } catch (e) {
      rethrow;
    }
  }
}
