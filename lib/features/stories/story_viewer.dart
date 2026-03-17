import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porno_social/providers/auth_providers.dart';
import 'package:porno_social/providers/stories_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class StoryViewer extends ConsumerStatefulWidget {
  final String storyId;

  const StoryViewer({super.key, required this.storyId});

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _markStoryAsViewed();
  }

  Future<void> _markStoryAsViewed() async {
    try {
      final authState = ref.read(authStateProvider);
      final user = authState.maybeWhen(data: (u) => u, orElse: () => null);
      if (user != null) {
        final storiesRepo = ref.read(storiesRepositoryProvider);
        await storiesRepo.addViewer(widget.storyId, user.uid);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      _videoController!.play();

      // Adjust duration based on video duration
      _progressController.duration = Duration(
        milliseconds: _videoController!.value.duration.inMilliseconds,
      );

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      // Handle video initialization error
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading video')));
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyByIdProvider(widget.storyId));

    return storyAsync.when(
      data: (story) {
        if (story == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Story not found')),
          );
        }

        if (story.mediaType == 'video' && _videoController == null) {
          _initializeVideoPlayer(story.mediaUrl);
        }

        // Start progress animation
        if (!_progressController.isAnimating) {
          _progressController.forward();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: BackButton(
              onPressed: () {
                _progressController.stop();
                Navigator.pop(context);
              },
            ),
          ),
          body: Stack(
            children: [
              // Media display
              Center(
                child: story.mediaType == 'image'
                    ? CachedNetworkImage(
                        imageUrl: story.mediaUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white),
                        ),
                      )
                    : _isVideoInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              // Progress bar at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 3,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFe8000a),
                      ),
                    ),
                  ],
                ),
              ),
              // Author info at bottom
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(story.authorAvatar),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getTimeAgo(story.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Text(
            'Error loading story',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
