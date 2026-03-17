import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:porno_social/features/subscriptions/content_gate.dart';
import 'package:porno_social/models/post.dart';
import 'package:porno_social/providers/post_providers.dart';
import 'package:porno_social/providers/auth_providers.dart';
import 'package:porno_social/features/stories/index.dart';
import 'package:porno_social/shared/widgets/report_button.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(mainFeedProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        title: const Text(
          ' PornoSocial',
          style: TextStyle(
            color: Color(0xFFe8000a),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              context.push('/create-post');
            },
            tooltip: 'Create Post',
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              context.push('/notifications');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: feedAsync.when(
        data: (posts) => Column(
          children: [
            const StoriesBar(),
            Expanded(
              child: _FeedListView(posts: posts, userId: userId, ref: ref),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe8000a)),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading feed',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(mainFeedProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe8000a),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const CreateStoryButton(),
    );
  }
}

class _FeedListView extends ConsumerWidget {
  final List<Post> posts;
  final String? userId;
  final WidgetRef ref;

  const _FeedListView({
    required this.posts,
    required this.userId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: posts.length + 1, // +1 for load more button
      itemBuilder: (context, index) {
        // Load more button at the end
        if (index == posts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(mainFeedProvider.notifier).loadMorePosts();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe8000a),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.expand_more),
                label: const Text('Load More'),
              ),
            ),
          );
        }

        return PostCard(post: posts[index], userId: userId, ref: ref);
      },
    );
  }
}

class PostCard extends ConsumerWidget {
  final Post post;
  final String? userId;
  final WidgetRef ref;

  const PostCard({
    super.key,
    required this.post,
    required this.userId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

        if (post.mediaUrls.isNotEmpty) _MediaDisplay(post: post),

        if (post.tags.isNotEmpty) _TagsDisplay(tags: post.tags),
      ],
    );

    return Card(
      color: const Color(0xFF111111),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info header
          _AuthorHeader(post: post),

          if (post.isSubscribersOnly)
            buildContentGate(post.authorId, postBody)
          else
            postBody,

          // Action bar (likes, comments, share)
          _PostActionBar(post: post, userId: userId, ref: ref),
        ],
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  final Post post;

  const _AuthorHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage: post.authorAvatar.isNotEmpty
                ? CachedNetworkImageProvider(post.authorAvatar)
                : null,
            child: post.authorAvatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          // Author name and timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTimestamp(post.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // More options menu
          PopupMenuButton<String>(
            color: const Color(0xFF222222),
            onSelected: (value) async {
              if (value == 'report') {
                await showReportDialog(
                  context,
                  targetType: 'post',
                  targetId: post.id,
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Report', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class _MediaDisplay extends StatelessWidget {
  final Post post;

  const _MediaDisplay({required this.post});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: post.mediaUrls.map((url) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: post.mediaType == MediaType.video
                  ? _VideoThumbnail(url: url)
                  : CachedNetworkImage(
                      imageUrl: url,
                      width: 300,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 300,
                        height: 200,
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFe8000a),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 300,
                        height: 200,
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String url;

  const _VideoThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/video-player?url=${Uri.encodeComponent(url)}');
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 200,
            color: Colors.black,
            child: const Icon(
              Icons.play_circle_fill,
              color: Color(0xFFe8000a),
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsDisplay extends StatelessWidget {
  final List<String> tags;

  const _TagsDisplay({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              border: Border.all(color: const Color(0xFFe8000a), width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: Color(0xFFe8000a),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PostActionBar extends ConsumerWidget {
  final Post post;
  final String? userId;
  final WidgetRef ref;

  const _PostActionBar({
    required this.post,
    required this.userId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final hasLikedAsync = ref.watch(userLikedPostProvider((post.id, userId!)));

    return Column(
      children: [
        const Divider(color: Color(0xFF222222), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Like button
              hasLikedAsync.when(
                data: (hasLiked) => Expanded(
                  child: _ActionButton(
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
                ),
                loading: () => Expanded(
                  child: _ActionButton(
                    icon: Icons.favorite_border,
                    iconColor: Colors.grey,
                    label: post.likeCount.toString(),
                    onPressed: () {},
                  ),
                ),
                error: (error, stack) => Expanded(
                  child: _ActionButton(
                    icon: Icons.favorite_border,
                    iconColor: Colors.grey,
                    label: post.likeCount.toString(),
                    onPressed: () {},
                  ),
                ),
              ),

              // Comment button
              Expanded(
                child: _ActionButton(
                  icon: Icons.comment_outlined,
                  iconColor: Colors.grey,
                  label: post.commentCount.toString(),
                  onPressed: () {
                    context.push('/posts/${post.id}');
                  },
                ),
              ),

              // Share button
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  iconColor: Colors.grey,
                  label: 'Share',
                  onPressed: () {
                    // Copy post link to clipboard
                    final shareLink = 'pornosocial://posts/${post.id}';
                    Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post link copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFFe8000a),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 18),
      label: Text(label, style: TextStyle(color: iconColor, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
