## FeedScreen Implementation Guide

### Overview
The refactored `FeedScreen` is a production-ready feed implementation for Porno Social, featuring infinite scroll pagination, proper like/unlike handling, media display, and comprehensive error handling.

---

## Features Implemented

### ✅ 1. **Riverpod State Management**
- Uses `mainFeedProvider` for feed data
- Uses `currentUserIdProvider` for user identification
- Uses `userLikedPostProvider` for like state
- Uses `likePostProvider` / `unlikePostProvider` for mutations

**Benefit:** Centralized state management, easy cache invalidation, built-in error handling

### ✅ 2. **Infinite Scroll Pagination**
- Load initial 20 posts via `mainFeedProvider`
- "Load More" button at the end of list
- Calls `loadMorePosts()` on the `MainFeedNotifier`
- Cursor-based pagination (no duplicates)

**Code:**
```dart
ElevatedButton.icon(
  onPressed: () {
    ref.read(mainFeedProvider.notifier).loadMorePosts();
  },
  child: const Text('Load More'),
)
```

### ✅ 3. **Like/Unlike with Proper State**
Each like button:
- Checks if current user has liked the post
- Shows filled heart if liked, outline if not
- Updates color (red when liked)
- Updates like count in real-time
- Invalidates related providers for cache refresh

**Code:**
```dart
hasLikedAsync.when(
  data: (hasLiked) => _ActionButton(
    icon: hasLiked ? Icons.favorite : Icons.favorite_border,
    iconColor: hasLiked ? const Color(0xFFe8000a) : Colors.grey,
    label: post.likeCount.toString(),
    onPressed: () {
      if (hasLiked) {
        ref.read(unlikePostProvider((post.id, userId!)));
      } else {
        ref.read(likePostProvider((post.id, userId!)));
      }
    },
  ),
  // ...
)
```

### ✅ 4. **Media Display**
- Supports images and videos
- Horizontal scrollable media gallery
- Cached network images for performance
- Loading placeholders
- Error fallbacks
- Video thumbnail with play icon

**Supported Media Types:**
- `MediaType.image` - Displays cached image
- `MediaType.video` - Shows video thumbnail with play icon
- `MediaType.text` - Text-only posts

### ✅ 5. **Tag Display**
- Styled hashtag pills
- Brand color (#e8000a)
- Clickable for search (TODO)

**Style:**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: const Color(0xFF1a1a1a),
    border: Border.all(color: const Color(0xFFe8000a), width: 0.5),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('#$tag'),
)
```

### ✅ 6. **Comprehensive Error Handling**
Three states handled:
- **Loading:** Spinner with brand color
- **Data:** Feed display with load more
- **Error:** Friendly error message with retry button

**Code:**
```dart
feedAsync.when(
  data: (posts) => _FeedListView(...),
  loading: () => const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe8000a)),
    ),
  ),
  error: (error, stack) => Center(
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        Text('Error loading feed'),
        ElevatedButton(
          onPressed: () => ref.refresh(mainFeedProvider),
          child: const Text('Retry'),
        ),
      ],
    ),
  ),
)
```

### ✅ 7. **Author Info Header**
- Avatar with fallback icon
- Author name
- Relative timestamps (e.g., "2h ago")
- More options menu (report post)

**Timestamp Formatting:**
- < 1 min: "now"
- < 1 hour: "Xm ago"
- < 1 day: "Xh ago"
- < 1 week: "Xd ago"
- Older: MM/DD/YYYY

### ✅ 8. **Clean Dark Theme**
- Background: `#080808` (near black)
- Cards: `#111111` (dark gray)
- Accent: `#e8000a` (brand red)
- Text: White with grey secondary
- Consistent spacing and typography

---

## Integration Guide

### 1. **Add FeedScreen to Navigation**
```dart
// In your app routing (app.dart or main.dart)
import 'package:porno_social/screens/feed_screen.dart';

// GoRouter configuration
GoRoute(
  path: '/feed',
  builder: (context, state) => const FeedScreen(),
),

// Or if using Navigator
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FeedScreen()),
);
```

### 2. **Ensure Auth is Working**
FeedScreen requires:
- `currentUserIdProvider` to be available
- User must be authenticated
- Auth state is managed via `FirebaseAuth`

```dart
// In your app wrapper
import 'package:porno_social/providers/auth_providers.dart';

// Check auth before showing feed
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) => user != null ? const FeedScreen() : const LoginScreen(),
  // ...
);
```

### 3. **Add Required Dependencies**
Ensure `pubspec.yaml` has:
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  cloud_firestore: ^5.0.0
  cached_network_image: ^3.3.0
  firebase_auth: ^5.0.0
```

### 4. **Set Up Firestore Indexes**
Create composite indexes for optimal performance:

```
Collections: posts
Fields: createdAt (Descending)

Collections: posts  
Fields: authorId (Ascending), createdAt (Descending)

Collections: posts
Fields: tags (Ascending), createdAt (Descending)
```

---

## TODO / Future Enhancements

### Currently Marked as TODO:
1. **Create Post Screen**
   ```dart
   IconButton(
     onPressed: () {
       // TODO: Navigate to create post screen
     },
   )
   ```

2. **Notifications**
   ```dart
   IconButton(
     onPressed: () {
       // TODO: Navigate to notifications
     },
   )
   ```

3. **Post Detail / Comments**
   ```dart
   _ActionButton(
     label: post.commentCount.toString(),
     onPressed: () {
       // TODO: Show comments sheet or navigate to post detail
     },
   )
   ```

4. **Share Post**
   ```dart
   _ActionButton(
     label: 'Share',
     onPressed: () {
       // TODO: Implement share functionality
     },
   )
   ```

5. **Video Player**
   ```dart
   class _VideoThumbnail extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       // TODO: Implement video player integration
     }
   }
   ```

6. **Tag Search**
   ```dart
   _TagsDisplay(
     onTagTap: (tag) {
       // TODO: Navigate to tag search results
     },
   )
   ```

---

## Component Breakdown

### `FeedScreen`
Main widget handling:
- Feed state management
- Error/Loading states
- AppBar with actions

### `_FeedListView`
ListView wrapper for:
- Post list rendering
- Load more button logic
- Buildable list with +1 for button

### `PostCard`
Individual post rendering:
- Accepts Post model, userId, and ref
- Composes all sub-components
- Dark theme styling

### `_AuthorHeader`
Author information display:
- Avatar (with CachedNetworkImage)
- Author name
- Timestamp with relative formatting
- More options menu

### `_MediaDisplay`
Media gallery:
- Horizontal scroll for multiple media
- Supports images and videos
- Loading indicators
- Error handling

### `_VideoThumbnail`
Video preview (placeholder for video player)

### `_TagsDisplay`
Hashtag display:
- Styled pills
- Brand color accents
- Tap-ready (TODO: search integration)

### `_PostActionBar`
Interaction buttons:
- Like/Unlike with real-time state
- Comment (opens detail)
- Share (TODO)
- Real-time like count updates

### `_ActionButton`
Reusable action button component:
- Icon + label
- Configurable colors
- Tap feedback

---

## State Management Flow

```
FeedScreen
├── mainFeedProvider (watch)
│   └── MainFeedNotifier
│       ├── _loadInitialFeed()
│       ├── loadMorePosts()
│       └── refresh()
├── currentUserIdProvider (watch)
└── PostCard (for each post)
    ├── userLikedPostProvider (family)
    ├── likePostProvider (family)
    └── unlikePostProvider (family)
```

### Data Flow Example: Liking a Post
1. User taps heart icon
2. `userLikedPostProvider` returns `hasLiked = false`
3. `ref.read(likePostProvider((postId, userId)))` called
4. PostRepository.likePost() executes:
   - Firestore batch update
   - Increments like count
   - Creates like document
5. Provider auto-invalidates:
   - `postByIdProvider(postId)` 
   - `userLikedPostProvider((postId, userId))`
6. Heart icon re-renders as filled (red)
7. Like count increments

---

## Performance Optimizations

### 1. **Cached Network Images**
Uses `cached_network_image` for:
- In-memory caching
- Disk persistence
- Less bandwidth usage

### 2. **Lazy Loading**
- Posts loaded page by page (20 per page)
- Only visible posts in memory
- Load more on demand

### 3. **State Caching**
- Like state cached per post
- Avoid re-fetching liked status
- Auto-invalidate on changes

### 4. **Firestore Batch Operations**
- Like/unlike uses transactions
- Atomic counter updates
- Prevents race conditions

---

## Styling Reference

### Colors
- **Primary Background:** `#080808`
- **Card Background:** `#111111`
- **Accent/Brand:** `#e8000a`
- **Secondary Text:** `#999999`
- **Borders/Dividers:** `#222222`

### Typography
- **Titles:** 14px, Bold (w600)
- **Body:** 14px, Regular (w400)
- **Secondary:** 12px, Regular
- **Font:** Default (usually Roboto on Android, SF Pro on iOS)

### Spacing
- **Card Margin:** 8px horizontal, 6px vertical
- **Padding:** 16px standard
- **Avatar Size:** 24px radius
- **Icon Size:** 18-28px

---

## Testing & Debugging

### Enable Dart Debug Logging
```dart
// In main.dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    // Enable Riverpod debugger
    ProviderContainer(
      overrides: [],
    );
  }
  runApp(const MyApp());
}
```

### Check Feed Provider State
```dart
// In your screen
final feedAsync = ref.watch(mainFeedProvider);
print('Feed state: $feedAsync');
```

### Fake Data for Testing
```dart
// Create test posts
final testPost = Post(
  id: 'test1',
  authorId: 'user1',
  authorName: 'Test User',
  authorAvatar: 'https://i.pravatar.cc/150',
  content: 'Test content',
  mediaUrls: [],
  mediaType: MediaType.text,
  isSubscribersOnly: false,
  likeCount: 42,
  commentCount: 5,
  createdAt: DateTime.now(),
  tags: ['test', 'demo'],
);
```

---

## Common Issues & Solutions

### Issue: Feed not loading
**Solution:** 
- Check Firestore security rules
- Verify user is authenticated
- Check network connectivity

### Issue: Likes not updating
**Solution:**
- Ensure `currentUserIdProvider` returns valid userId
- Check Firestore batch write permissions
- Verify post exists before liking

### Issue: Images not displaying
**Solution:**
- Check media URLs are valid
- Verify Firebase Storage permissions
- Check image format (JPG, PNG supported)

### Issue: Slow pagination
**Solution:**
- Limit posts per page (currently 20)
- Use composite Firestore indexes
- Enable app-side image caching

---

## Next Steps

1. **Implement Create Post Screen** - Use `createPostProvider`
2. **Add Post Detail Page** - Show all comments and replies
3. **Implement Following Feed** - Use `followingFeedProvider`
4. **Add Real-time Updates** - Switch to StreamProviders
5. **Implement Notifications** - Listen for new posts from followed users
6. **Add Video Playback** - Integrate `video_player` package
7. **Implement Recommendations** - Use `personalizedFeedProvider` or `curatedContentProvider`
