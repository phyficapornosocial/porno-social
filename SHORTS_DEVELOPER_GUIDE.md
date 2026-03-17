# Shorts Feature - Developer Reference

## Architecture Overview

### Directory Structure
```
lib/
├── features/
│   └── shorts/
│       └── shorts_screen.dart          # UI Components
├── models/
│   └── short.dart                      # Data model
├── providers/
│   └── shorts_providers.dart           # State management & repository
└── app.dart                            # Routing
```

## Data Flow

```
ShortsScreen (UI)
    ↓
watches shortsProvider (Riverpod)
    ↓
ShortsRepository.getShortsStream()
    ↓
Firestore (shorts collection)
    ↓
ShortVideoPlayer (per Short)
    ↓
VideoPlayerController (video_player package)
```

## Component APIs

### ShortsScreen
**Type:** `ConsumerWidget`

**Purpose:** Main entry point for the shorts feature. Displays vertical PageView of videos.

**Props:** None (route parameter: `/shorts`)

**Watches:**
- `shortsProvider` - Stream of all shorts

**Provides:**
- PageView with ShortVideoPlayer items
- Loading and error states
- View count increment on page change

```dart
// Usage
context.go('/shorts');
```

### ShortVideoPlayer
**Type:** `ConsumerStatefulWidget`

**Purpose:** Individual video player with controls and social interactions.

**Props:**
```dart
final Short short;              // Data model
final ShortsRepository shortsRepository;  // For updates
```

**State:**
- `_controller` - VideoPlayerController
- `_isMuted` - Mute state
- `_isLiked` - Like state
- `_showPlayButton` - UI display state

**Methods:**
- `_initializeVideo()` - Initialize video player
- `_togglePlay()` - Play/pause toggle
- `_toggleMute()` - Mute toggle
- `_toggleLike()` - Like/unlike
- `_shareShort()` - Share action

**UI Layers:**
1. Video player (center)
2. Play button overlay (when paused)
3. Top gradient with author info
4. Bottom gradient with caption/tags
5. Right-side control panel

### _ControlButton
**Type:** `StatelessWidget`

**Purpose:** Reusable button for control panel.

**Props:**
```dart
final IconData icon;
final String label;
final VoidCallback onPressed;
final Color color;
```

## Data Models

### Short Model
```dart
class Short {
  final String id;                    // Doc ID from Firestore
  final String authorId;              // User ID of creator
  final String authorName;            // Display name
  final String authorAvatar;          // Avatar URL
  final String videoUrl;              // Video file URL
  final String? caption;              // Optional caption
  final int likeCount;                // Total likes
  final int commentCount;             // Total comments
  final int shareCount;               // Total shares
  final int viewCount;                // Total views
  final DateTime createdAt;           // Creation timestamp
  final List<String> tags;            // Hash tags
  final bool isSubscribersOnly;       // Paywall flag
}
```

**Serialization:**
```dart
// From Firestore document
Short.fromFirestore(DocumentSnapshot doc)

// To Map for updates
Map<String, dynamic> toMap()
```

## State Management (Riverpod)

### Providers

#### shortsProvider (StreamProvider)
```dart
final shortsProvider = StreamProvider<List<Short>>((ref) {
  // Returns: Stream<List<Short>>
  // Ordered by createdAt (descending)
  // Auto-updates when Firestore changes
});
```

**Usage:**
```dart
final shorts = ref.watch(shortsProvider);
// Or with error handling:
shorts.when(
  loading: () => LoadingWidget(),
  error: (err, stack) => ErrorWidget(),
  data: (shorts) => VideoListWidget(),
);
```

#### shortByIdProvider (FutureProvider.family)
```dart
final shortByIdProvider = FutureProvider.family<Short?, String>((ref, shortId) {
  // Returns: Future<Short?>
  // Fetches single short by ID
});
```

**Usage:**
```dart
final short = ref.watch(shortByIdProvider('shortId123'));
```

#### shortsRepositoryProvider (Provider)
```dart
final shortsRepositoryProvider = Provider((ref) {
  return ShortsRepository(FirebaseFirestore.instance);
});
```

**Usage:**
```dart
final repo = ref.read(shortsRepositoryProvider);
await repo.likeShort('shortId');
```

## Repository (Data Access)

### ShortsRepository

```dart
class ShortsRepository {
  // Constructor
  ShortsRepository(this._firestore);

  // Get shorts stream
  Stream<List<Short>> getShortsStream()

  // Increment view count
  Future<void> incrementViewCount(String shortId)

  // Like/Unlike
  Future<void> likeShort(String shortId)
  Future<void> unlikeShort(String shortId)

  // Share
  Future<void> shareShort(String shortId)
}
```

**Implementation Details:**

All methods use `FieldValue.increment()` for atomic updates:
```dart
await _firestore.collection('shorts').doc(shortId).update({
  'viewCount': FieldValue.increment(1),
});
```

This prevents race conditions and ensures consistency.

## Firestore Schema

### Collection: `shorts`

```
shorts/
├── shortId1/
│   ├── authorId: string
│   ├── authorName: string
│   ├── authorAvatar: string (URL)
│   ├── videoUrl: string (URL)
│   ├── caption: string (optional, null)
│   ├── likeCount: number
│   ├── commentCount: number
│   ├── shareCount: number
│   ├── viewCount: number
│   ├── createdAt: timestamp
│   ├── tags: array<string>
│   └── isSubscribersOnly: boolean
```

### Document Creation Example

```javascript
// Firebase Cloud Function or Admin SDK
await db.collection('shorts').doc(shortId).set({
  authorId: userId,
  authorName: userData.displayName,
  authorAvatar: userData.avatarUrl,
  videoUrl: 'gs://bucket/video.mp4',
  caption: 'Check this out!',
  likeCount: 0,
  commentCount: 0,
  shareCount: 0,
  viewCount: 0,
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  tags: ['funny', 'viral'],
  isSubscribersOnly: false,
});
```

## UI Customization

### Styling Constants (Add to theme)

```dart
const double controlButtonSize = 24;
const double controlButtonPadding = 12;
const Color controlButtonBackground = Colors.black26;
const double authorAvatarRadius = 20;
const double fontSize14 = 14;
```

### Theming

Current implementation supports Material 3 and respects theme context:
```dart
Theme.of(context).colorScheme.primary  // For custom colors
Theme.of(context).textTheme.headlineSmall  // Typography
```

## Video Player Configuration

### Video Player Controller

```dart
_controller = VideoPlayerController.networkUrl(
  Uri.parse(widget.short.videoUrl),
);

_controller.initialize().then((_) {
  _controller.play();
  _controller.setLooping(true);
  _controller.setVolume(1); // 0 = mute, 1 = full
});
```

### Supported URL Schemes
- HTTPS URLs (recommended)
- HTTP URLs (if allowed by CORS)
- Asset URLs (local files)
- Firebase Storage URLs

### Video Formats
Supported by platform default:
- **Android:** MP4, WebM
- **iOS:** MP4, MOV
- **Web:** MP4, WebM

## Error Handling

### Firestore Errors

```dart
try {
  await shortsRepository.likeShort(shortId);
} on FirebaseException catch (e) {
  print('Firebase error: ${e.code} - ${e.message}');
  // Show user-friendly error
} catch (e) {
  print('Unexpected error: $e');
}
```

### Video Loading Errors

```dart
_controller = VideoPlayerController.networkUrl(Uri.parse(url))
  ..initialize().catchError((error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video error: $error')),
    );
  });
```

## Performance Optimization

### Lazy Loading

```dart
// Load only visible items + 1
final shortsProvider = StreamProvider<List<Short>>((ref) {
  return FirebaseFirestore.instance
      .collection('shorts')
      .orderBy('createdAt', descending: true)
      .limit(20)  // Load 20 at a time
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Short.fromFirestore).toList());
});
```

### Video Pre-buffering

```dart
// Pre-load next/previous videos
void _preloadAdjacentVideos(List<Short> shorts, int currentIndex) {
  if (currentIndex > 0) {
    _preloadVideo(shorts[currentIndex - 1].videoUrl);
  }
  if (currentIndex < shorts.length - 1) {
    _preloadVideo(shorts[currentIndex + 1].videoUrl);
  }
}
```

### Memory Management

```dart
@override
void dispose() {
  _controller.dispose();  // Critical for memory
  super.dispose();
}

@override
void didUpdateWidget(ShortVideoPlayer oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.short.id != widget.short.id) {
    _controller.dispose();     // Dispose old controller
    _initializeVideo();        // Initialize new one
  }
}
```

## Testing

### Unit Tests

```dart
test('Short.fromFirestore deserializes correctly', () {
  final doc = MockDocSnapshot({
    'authorId': 'user123',
    'videoUrl': 'https://example.com/video.mp4',
    // ... other fields
  });
  
  final short = Short.fromFirestore(doc);
  expect(short.authorId, 'user123');
});
```

### Widget Tests

```dart
testWidgets('ShortsScreen displays videos', (WidgetTester tester) async {
  await tester.pumpWidget(
    FakeAsyncRunner((fake) async {
      // Mock shortsProvider
      // Pump widget
      // Verify PageView displays
    }),
  );
});
```

## Extending the Feature

### Add Comments

1. Create `models/comment.dart`
2. Add `comments` subcollection to shorts
3. Create `CommentScreen` widget
4. Connect comment button

### Add Creator Profile Navigation

```dart
void _navigateToProfile(String userId) {
  context.go('/profile/$userId');
}
```

Then update author info tap:
```dart
GestureDetector(
  onTap: () => _navigateToProfile(widget.short.authorId),
  child: AuthorInfo(short: widget.short),
)
```

### Add Bookmarking

1. Create `userBookmarks` collection mapping users to shorts
2. Add save button to control panel
3. Create provider to watch user bookmarks

### Add Trending Sort

```dart
final trendingShortsProvider = StreamProvider<List<Short>>((ref) {
  return FirebaseFirestore.instance
      .collection('shorts')
      .where('createdAt', isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
      .orderBy('createdAt', descending: true)
      .orderBy('viewCount', descending: true)  // Requires composite index
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Short.fromFirestore).toList());
});
```

## Useful References

- [video_player documentation](https://pub.dev/packages/video_player)
- [Riverpod docs](https://riverpod.dev)
- [Firestore best practices](https://firebase.google.com/docs/firestore/best-practices)
- [Flutter performance guide](https://flutter.dev/docs/testing/ui-performance)

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Video won't play | Check URL is HTTPS, verify CORS, test in browser |
| App crashes on swipe | Ensure disposal in `didUpdateWidget`, check for memory leaks |
| Like not updating | Check Firestore permissions, verify collection rules |
| Memory leak | Dispose VideoPlayerController in dispose(), don't leak streams |
| Freezing app | Add pagination, reduce initial load, pre-buffer less aggressively |

## Code Quality Guidelines

- Always handle errors with try-catch or Firebase exception handling
- Dispose resources in `dispose()` method
- Use `const` constructors for widgets
- Keep components small and focused
- Document public APIs
- Add null-safety checks
- Use `late` keyword properly for controller initialization
