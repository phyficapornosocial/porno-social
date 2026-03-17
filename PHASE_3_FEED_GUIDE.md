## Phase 3 — Feed Implementation Guide

### Overview
This document covers the complete feed functionality implemented for Porno Social, including data models, services, repositories, and providers.

---

## 1. Data Models

### Post Model (`models/post.dart`)
Represents a single post in the feed.

**Fields:**
- `id`: Unique post identifier (Firestore doc ID)
- `authorId`: User ID of the post creator
- `authorName`: Author's display name (denormalized)
- `authorAvatar`: Author's avatar URL (denormalized)
- `content`: Post text content
- `mediaUrls`: List of media file URLs
- `mediaType`: `MediaType.image`, `.video`, or `.text`
- `isSubscribersOnly`: Boolean for subscription-gated content
- `likeCount`: Number of likes (cached)
- `commentCount`: Number of comments (cached)
- `createdAt`: Post creation timestamp
- `tags`: List of hashtags/interest tags

**Usage:**
```dart
final post = Post(
  id: 'post123',
  authorId: 'user123',
  authorName: 'John Doe',
  authorAvatar: 'https://...',
  content: 'Check out this content!',
  mediaUrls: ['https://...'],
  mediaType: MediaType.image,
  isSubscribersOnly: false,
  likeCount: 42,
  commentCount: 5,
  createdAt: DateTime.now(),
  tags: ['fitness', 'wellness'],
);

// Serialize to Firestore
final data = post.toFirestore();

// Deserialize from Firestore
final post = Post.fromFirestore(snapshot);
```

---

## 2. Firestore Schema

### Posts Collection
```
/posts/{postId}
  ├─ authorId: String
  ├─ authorName: String
  ├─ authorAvatar: String
  ├─ content: String
  ├─ mediaUrls: List<String>
  ├─ mediaType: String ('image' | 'video' | 'text')
  ├─ isSubscribersOnly: Boolean
  ├─ likeCount: Int
  ├─ commentCount: Int
  ├─ createdAt: Timestamp
  ├─ tags: List<String>
  ├─ likes/{userId}
  │   └─ likedAt: Timestamp
  └─ comments/{commentId}
      ├─ userId: String
      ├─ authorName: String
      ├─ authorAvatar: String
      ├─ content: String
      ├─ createdAt: Timestamp
      └─ likeCount: Int
```

### Firestore Security Rules
```javascript
match /posts/{postId} {
  // Anyone can read posts
  allow read;
  
  // Only author can write/update/delete their posts
  allow create: if request.auth.uid != null;
  allow update, delete: if request.auth.uid == resource.data.authorId;
  
  // Likes subcollection
  match /likes/{userId} {
    allow read;
    allow create, delete: if request.auth.uid == userId;
  }
  
  // Comments subcollection
  match /comments/{commentId} {
    allow read;
    allow create: if request.auth.uid != null;
    allow delete: if request.auth.uid == resource.data.userId 
                   || request.auth.uid == get(/databases/$(database)/documents/posts/$(postId)).data.authorId;
  }
}
```

---

## 3. Repository Layer

### PostRepository (`repositories/post_repository.dart`)
Handles all data access operations for posts.

**Key Methods:**

#### Post CRUD
```dart
final postId = await postRepository.createPost(
  authorId: 'user123',
  authorName: 'John Doe',
  authorAvatar: 'https://...',
  content: 'My content',
  mediaUrls: ['https://...'],
  mediaType: MediaType.image,
  isSubscribersOnly: false,
  tags: ['fitness'],
);

final post = await postRepository.getPostById('post123');
final userPosts = await postRepository.getPostsByAuthor('user123');

await postRepository.updatePost('post123', 
  content: 'Updated content',
  tags: ['fitness', 'wellness'],
);

await postRepository.deletePost('post123');
```

#### Feed Queries
```dart
// Get main feed (all posts, newest first)
final feed = await postRepository.getMainFeed(limit: 20);

// Paginated feed with cursor
final nextPage = await postRepository.getMainFeedPaginated(
  limit: 20,
  startAfterDocument: lastDocument,
);

// Posts from followed creators
final followingFeed = await postRepository.getFollowingFeed(
  followedUserIds: ['user1', 'user2', 'user3'],
  limit: 20,
);

// Search by tags
final results = await postRepository.searchByTags(['fitness', 'wellness']);

// Search by content (prefix match)
final searchResults = await postRepository.searchByContent('workout');

// Trending posts (by like count)
final trending = await postRepository.getTrendingPosts();
```

#### Like Management
```dart
// Check if user liked a post
final hasLiked = await postRepository.hasUserLiked('post123', 'user456');

// Like a post
await postRepository.likePost('post123', 'user456');

// Unlike a post
await postRepository.unlikePost('post123', 'user456');

// Get all users who liked a post
final likers = await postRepository.getPostLikes('post123');
```

#### Comment Management
```dart
// Add comment
final commentId = await postRepository.addComment(
  postId: 'post123',
  userId: 'user456',
  authorName: 'Jane Doe',
  authorAvatar: 'https://...',
  content: 'Great post!',
);

// Get comments
final comments = await postRepository.getPostComments('post123', limit: 50);

// Delete comment
await postRepository.deleteComment('post123', 'comment456');
```

---

## 4. Service Layer

### FeedService (`services/feed_service.dart`)
Combines repositories for higher-level operations.

**Key Methods:**

```dart
// Get feed personalized by user interests
final feed = await feedService.getPersonalizedFeed('user123');

// Get feed from followed creators
final followingFeed = await feedService.getFollowingFeed(
  'user123',
  followedUserIds: ['user1', 'user2'],
);

// Get feed with enriched author data
final enriched = await feedService.getEnrichedFeed('user123');

// Global search (posts + users)
final results = await feedService.globalSearch('query');

// Creator profile with posts
final profile = await feedService.getCreatorProfile('user123');
// Returns: { 'user': User, 'posts': List<Post>, 'postCount': int, 'isCreator': bool }

// Get trending creators
final trending = await feedService.getTrendingCreators(limit: 20);
// Returns: [{ 'user': User, 'postCount': int }, ...]

// Get curated content by interests
final curated = await feedService.getCuratedContent(['fitness', 'wellness']);
```

---

## 5. Provider Layer

### Post Providers (`providers/post_providers.dart`)
Riverpod providers for post-related state management.

**Main Feed Provider:**
```dart
// StateNotifier for infinite scroll pagination
final mainFeedProvider = StateNotifierProvider<MainFeedNotifier, AsyncValue<List<Post>>>;

// Usage in widgets
@override
Widget build(BuildContext context, WidgetRef ref) {
  final feedAsync = ref.watch(mainFeedProvider);
  
  return feedAsync.when(
    data: (posts) => ListView(
      children: [
        ...posts.map((post) => PostCard(post: post)),
        // Load more button
        ElevatedButton(
          onPressed: () => ref.read(mainFeedProvider.notifier).loadMorePosts(),
          child: const Text('Load More'),
        ),
      ],
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
  );
}

// Refresh feed
ref.read(mainFeedProvider.notifier).refresh();
```

### User & Feed Providers (`providers/user_and_feed_providers.dart`)
Higher-level providers combining user and feed operations.

**Key Providers:**

```dart
// Personalized feed based on user interests
final personalizedFeedAsync = ref.watch(personalizedFeedProvider('user123'));

// Following feed
final followingAsync = ref.watch(followingFeedProvider(
  ('user123', ['creator1', 'creator2']),
));

// Enriched feed with author info
final enrichedAsync = ref.watch(enrichedFeedProvider('user123'));

// Global search
final searchResults = ref.watch(globalSearchProvider('search query'));
// Returns: { 'posts': List<Post>, 'users': List<User> }

// Creator profile
final creatorAsync = ref.watch(creatorProfileProvider('creator123'));
// Returns: { 'user': User, 'posts': List<Post>, 'postCount': int, 'isCreator': bool }

// Trending creators
final trendinCreatorsAsync = ref.watch(trendingCreatorsProvider);

// Curated content
final curatedAsync = ref.watch(curatedContentProvider(['fitness', 'wellness']));
```

### Like Providers
```dart
// Check if user liked a post
final hasLikedAsync = ref.watch(userLikedPostProvider(('post123', 'user456')));

// Like a post
ref.read(likePostProvider(('post123', 'user456')));

// Unlike a post
ref.read(unlikePostProvider(('post123', 'user456')));
```

### Post CRUD Providers
```dart
// Create a post
final result = await ref.read(createPostProvider(CreatePostParams(
  authorId: 'user123',
  authorName: 'John Doe',
  authorAvatar: 'https://...',
  content: 'My post',
  mediaUrls: ['https://...'],
  mediaType: MediaType.image,
  tags: ['fitness'],
)).future);

// Delete a post
ref.read(deletePostProvider(('post123', 'user123')));
```

---

## 6. Usage Examples

### Example 1: Display Main Feed with Pagination
```dart
class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(mainFeedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: feedAsync.when(
        data: (posts) => ListView.builder(
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index < posts.length) {
              return PostCard(post: posts[index]);
            } else {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(mainFeedProvider.notifier).loadMorePosts();
                  },
                  child: const Text('Load More'),
                ),
              );
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### Example 2: Create a Post
```dart
class CreatePostScreen extends ConsumerWidget {
  final TextEditingController _contentController = TextEditingController();
  final List<String> selectedTags = [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);

    return user.when(
      data: (userProfile) => Scaffold(
        appBar: AppBar(title: const Text('Create Post')),
        body: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
            // Tag selection UI
            ElevatedButton(
              onPressed: () async {
                final postId = await ref.read(createPostProvider(
                  CreatePostParams(
                    authorId: userProfile!.uid,
                    authorName: userProfile.displayName,
                    authorAvatar: userProfile.avatarUrl,
                    content: _contentController.text,
                    mediaUrls: [],
                    mediaType: MediaType.text,
                    tags: selectedTags,
                  ),
                ).future);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### Example 3: Like/Unlike a Post
```dart
class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final hasLikedAsync = ref.watch(userLikedPostProvider((post.id, userId ?? '')));

    return Card(
      child: Column(
        children: [
          Text(post.content),
          hasLikedAsync.when(
            data: (hasLiked) => IconButton(
              icon: Icon(hasLiked ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                if (userId != null) {
                  if (hasLiked) {
                    ref.read(unlikePostProvider((post.id, userId)));
                  } else {
                    ref.read(likePostProvider((post.id, userId)));
                  }
                }
              },
            ),
            loading: () => const SizedBox(width: 24, height: 24),
            error: (error, stack) => const Icon(Icons.error),
          ),
          Text('${post.likeCount} likes'),
        ],
      ),
    );
  }
}
```

---

## 7. Performance Considerations

### Caching
- Post like/comment counts are **denormalized** in the main post document for performance
- Use `FieldValue.increment()` for atomic updates to avoid race conditions

### Pagination
- Use cursor-based pagination (`startAfterDocument`) for efficient querying
- Load 20 posts per page for responsive UX

### Firestore Indexes
Create composite indexes for queries:
```
Collections: posts
Field: createdAt (Descending)
Collection: posts
Fields: authorId (Ascending), createdAt (Descending)

Collections: posts
Fields: tags (Ascending), createdAt (Descending)
```

### Real-time Updates
- Use `StreamProvider` for real-time feeds (requires proper Firestore rules)
- Implement proper cleanup to avoid memory leaks

---

## 8. Next Implementation Steps

### Phase 4 — Monetization
- Subscription model
- Payment processing
- Creator earnings tracking

### Phase 5 — Social Features
- Follow/followers system
- Private messaging
- Notifications
- User blocking/reporting

### Phase 6 — Advanced Features
- Recommendations engine
- Content moderation
- Analytics dashboard
- Admin tools
