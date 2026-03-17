# Shorts Feature - Quick Start Guide

## Testing the Shorts Feature

### 1. Prerequisites
- ✅ Firebase project initialized (already done)
- ✅ `video_player: ^2.8.0` dependency (already in pubspec.yaml)
- ✅ Firestore database setup
- ✅ All Phase 4 code files created

### 2. Create Test Data in Firestore

Create a `shorts` collection with sample documents:

```json
{
  "authorId": "user123",
  "authorName": "Creator One",
  "authorAvatar": "https://via.placeholder.com/150",
  "videoUrl": "https://example.com/video1.mp4",
  "caption": "This is an amazing short video!",
  "likeCount": 245,
  "commentCount": 12,
  "shareCount": 8,
  "viewCount": 1250,
  "createdAt": 1710710400000,
  "tags": ["funny", "viral", "comedy"],
  "isSubscribersOnly": false
}
```

**Quick video URLs for testing:**
- https://commondatastorage.googleapis.com/gtv-videos-library/sample/BigBuckBunny.mp4
- https://commondatastorage.googleapis.com/gtv-videos-library/sample/ElephantsDream.mp4
- https://commondatastorage.googleapis.com/gtv-videos-library/sample/ForBiggerBlazes.mp4
- https://commondatastorage.googleapis.com/gtv-videos-library/sample/ForBiggerEscapes.mp4

### 3. Build and Run

```bash
flutter clean
flutter pub get
flutter run
```

### 4. Navigate to Shorts

Once logged in:
```dart
context.go('/shorts');
```

Or add a navigation button to your HomeScreen pointing to `/shorts`.

### 5. Test Features

#### Video Playback
- [ ] Video auto-plays when visible
- [ ] Tapping video toggles play/pause
- [ ] Play button overlay shows when paused
- [ ] Video loops back to start when done

#### Controls
- [ ] Mute button toggles sound
- [ ] Mute icon changes (volume_up/volume_off)
- [ ] Like button toggles heart icon
- [ ] Like count updates

#### Social Features
- [ ] Share button increments share count
- [ ] Comment button shows placeholder
- [ ] Author info displays correctly
- [ ] Caption displays if present
- [ ] Tags display (max 3 shown)

#### Navigation
- [ ] Swiping up/down changes videos
- [ ] Smooth transitions between videos
- [ ] Previous video stops playing
- [ ] View count increments for new video
- [ ] No app crashes or memory leaks

#### Error Handling
- [ ] Invalid URL shows error message
- [ ] Network error displays snackbar
- [ ] Can recover from errors
- [ ] Loading spinner shows initially

### 6. Firebase Firestore Rules

Update your Firestore rules (in Firebase Console):

```firestore
// Add this to your existing rules:
match /shorts/{shortId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid;
  allow update: if request.auth != null;
  allow delete: if request.auth.uid == resource.data.authorId;
}
```

### 7. Troubleshooting

**Video won't play:**
- Check video URL is valid and accessible
- Verify network connectivity
- Check Firebase rules allow read access

**Crashes on page change:**
- Ensure VideoPlayerController is properly disposed
- Check for memory leaks with DevTools
- Verify Firestore data structure matches Short model

**Blank screen after liking:**
- Check Firestore update permissions
- Verify field names match exactly
- Check browser console for errors

**Performance issues:**
- Limit number of shorts in initial load
- Add pagination for large datasets
- Cache video thumbnails
- Consider pre-buffering next video

### 8. Next Steps

1. **Add to HomeScreen navigation:**
   - Add button/tab to navigate to `/shorts`
   - Include in bottom navigation

2. **Implement Comments:**
   - Create CommentsScreen for short-specific comments
   - Hook up comment button to navigate

3. **User Tracking:**
   - Track user's liked shorts
   - Prevent duplicate likes
   - Show saved/bookmarked shorts

4. **Advanced Features:**
   - Search shorts by tags
   - Filter by creator
   - Trending shorts calculation
   - Share to external platforms

5. **Performance:**
   - Implement video caching
   - Add pagination/infinite scroll
   - Pre-buffer next videos
   - Optimize image loading

### 9. File Locations

Key files for reference:
- Main screen: [lib/features/shorts/shorts_screen.dart](../lib/features/shorts/shorts_screen.dart)
- Data model: [lib/models/short.dart](../lib/models/short.dart)
- Providers: [lib/providers/shorts_providers.dart](../lib/providers/shorts_providers.dart)
- Routing: [lib/app.dart](../lib/app.dart)
- Rules: [FIRESTORE_RULES.md](./FIRESTORE_RULES.md)
- Full guide: [PHASE_4_SHORTS_GUIDE.md](./PHASE_4_SHORTS_GUIDE.md)

### 10. Performance Tips

```dart
// In production, add pagination:
final shortsProvider = StreamProvider<List<Short>>((ref) {
  return FirebaseFirestore.instance
      .collection('shorts')
      .orderBy('createdAt', descending: true)
      .limit(20)  // Add limit
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
      });
});
```

For infinite scroll, use `FirebaseFirestore.paginate()` with cursor.

### 11. Analytics Integration (Future)

```dart
// Track views:
ref.read(shortsRepositoryProvider).incrementViewCount(shorts[index].id);

// Track engagement:
/shorts/{id}/views
/shorts/{id}/likes
/shorts/{id}/shares
/shorts/{id}/avgViewDuration
```

---

**Questions?** Refer to [PHASE_4_SHORTS_GUIDE.md](./PHASE_4_SHORTS_GUIDE.md) for detailed documentation.
