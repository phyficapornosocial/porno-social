import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:porno_social/models/post.dart';
import 'package:porno_social/repositories/post_repository.dart';

// Post repository provider
final postRepositoryProvider = Provider((ref) {
  return PostRepository();
});

// ============ Main Feed Providers ============

/// Main feed posts (paginated)
final mainFeedProvider =
    StateNotifierProvider<MainFeedNotifier, AsyncValue<List<Post>>>((ref) {
      return MainFeedNotifier(ref.watch(postRepositoryProvider));
    });

class MainFeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final PostRepository _postRepository;
  DocumentSnapshot? _lastDocument;

  MainFeedNotifier(this._postRepository) : super(const AsyncValue.loading()) {
    _loadInitialFeed();
  }

  Future<void> _loadInitialFeed() async {
    try {
      state = const AsyncValue.loading();
      final posts = await _postRepository.getMainFeed();
      state = AsyncValue.data(posts);
      _lastDocument = null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadMorePosts() async {
    try {
      if (state.hasValue && state.value != null) {
        final posts = state.value!;
        final newPosts = await _postRepository.getMainFeedPaginated(
          limit: 20,
          startAfterDocument: _lastDocument,
        );

        if (newPosts.isNotEmpty) {
          _lastDocument = null; // Reset for Firestore query
          state = AsyncValue.data([...posts, ...newPosts]);
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadInitialFeed();
  }
}

// ============ Single Post Provider ============

/// Get a single post by ID
final postByIdProvider = FutureProvider.family<Post?, String>((
  ref,
  postId,
) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostById(postId);
});

// ============ User's Posts Provider ============

/// Get all posts by a specific user
final userPostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPostsByAuthor(userId);
});

// ============ Search & Discovery Providers ============

/// Search posts by tags
final searchPostsByTagsProvider =
    FutureProvider.family<List<Post>, List<String>>((ref, tags) async {
      final repository = ref.watch(postRepositoryProvider);
      return repository.searchByTags(tags);
    });

/// Search posts by content
final searchPostsByContentProvider = FutureProvider.family<List<Post>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.searchByContent(query);
});

/// Get trending posts
final trendingPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getTrendingPosts();
});

// ============ Like Providers ============

/// Check if current user has liked a post
final userLikedPostProvider =
    FutureProvider.family<bool, (String postId, String userId)>((
      ref,
      args,
    ) async {
      final (postId, userId) = args;
      final repository = ref.watch(postRepositoryProvider);
      return repository.hasUserLiked(postId, userId);
    });

/// Like a post
final likePostProvider =
    FutureProvider.family<void, (String postId, String userId)>((
      ref,
      args,
    ) async {
      final (postId, userId) = args;
      final repository = ref.watch(postRepositoryProvider);
      await repository.likePost(postId, userId);
      // Invalidate related providers
      ref.invalidate(postByIdProvider(postId));
      ref.invalidate(userLikedPostProvider((postId, userId)));
    });

/// Unlike a post
final unlikePostProvider =
    FutureProvider.family<void, (String postId, String userId)>((
      ref,
      args,
    ) async {
      final (postId, userId) = args;
      final repository = ref.watch(postRepositoryProvider);
      await repository.unlikePost(postId, userId);
      // Invalidate related providers
      ref.invalidate(postByIdProvider(postId));
      ref.invalidate(userLikedPostProvider((postId, userId)));
    });

// ============ Comment Providers ============

/// Get comments for a post
final postCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      postId,
    ) async {
      final repository = ref.watch(postRepositoryProvider);
      return repository.getPostComments(postId);
    });

/// Create a post (managed state)
final createPostProvider = FutureProvider.family<String, CreatePostParams>((
  ref,
  params,
) async {
  final repository = ref.watch(postRepositoryProvider);
  final postId = await repository.createPost(
    authorId: params.authorId,
    authorName: params.authorName,
    authorAvatar: params.authorAvatar,
    content: params.content,
    mediaUrls: params.mediaUrls,
    mediaType: params.mediaType,
    isSubscribersOnly: params.isSubscribersOnly,
    tags: params.tags,
  );

  // Invalidate main feed to include the new post
  ref.invalidate(mainFeedProvider);
  ref.invalidate(userPostsProvider(params.authorId));

  return postId;
});

// ============ Delete Post Provider ============

/// Delete a post
final deletePostProvider =
    FutureProvider.family<void, (String postId, String userId)>((
      ref,
      args,
    ) async {
      final (postId, userId) = args;
      final repository = ref.watch(postRepositoryProvider);
      await repository.deletePost(postId);

      // Invalidate related providers
      ref.invalidate(postByIdProvider(postId));
      ref.invalidate(userPostsProvider(userId));
      ref.invalidate(mainFeedProvider);
    });

// ============ Helper Classes ============

class CreatePostParams {
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final bool isSubscribersOnly;
  final List<String> tags;

  CreatePostParams({
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.mediaUrls,
    required this.mediaType,
    this.isSubscribersOnly = false,
    required this.tags,
  });
}
