import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/providers/stories_providers.dart';
import 'package:porno_social/features/stories/story_viewer.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return storiesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewer(storyId: story.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: story.isViewed
                                ? [Colors.grey[400]!, Colors.grey[600]!]
                                : const [Color(0xFFe8000a), Color(0xFF8B0000)],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(story.authorAvatar),
                          onBackgroundImageError: (exception, stackTrace) {
                            // Handle image load error
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          story.authorName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 90,
        child: Center(
          child: Text(
            'Error loading stories',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
