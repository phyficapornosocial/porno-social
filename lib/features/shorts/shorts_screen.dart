import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:porno_social/models/short.dart';
import 'package:porno_social/providers/shorts_providers.dart';

class ShortsScreen extends ConsumerWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsStream = ref.watch(shortsProvider);

    return shortsStream.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading shorts: $error'),
            ],
          ),
        ),
      ),
      data: (shorts) {
        if (shorts.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No shorts available')),
          );
        }

        return Scaffold(
          body: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: shorts.length,
            onPageChanged: (index) {
              // Optionally increment view count when video comes into view
              ref
                  .read(shortsRepositoryProvider)
                  .incrementViewCount(shorts[index].id);
            },
            itemBuilder: (context, index) => ShortVideoPlayer(
              short: shorts[index],
              shortsRepository: ref.read(shortsRepositoryProvider),
            ),
          ),
        );
      },
    );
  }
}

class ShortVideoPlayer extends ConsumerStatefulWidget {
  final Short short;
  final ShortsRepository shortsRepository;

  const ShortVideoPlayer({
    super.key,
    required this.short,
    required this.shortsRepository,
  });

  @override
  ConsumerState<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends ConsumerState<ShortVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isMuted = false;
  bool _isLiked = false;
  bool _showPlayButton = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.short.videoUrl))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {});
                  _controller.play();
                  _controller.setLooping(true);
                }
              })
              .catchError((error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Video loading error: $error')),
                  );
                }
              });
  }

  @override
  void didUpdateWidget(ShortVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.short.id != widget.short.id) {
      _controller.dispose();
      _isMuted = false;
      _isLiked = false;
      _showPlayButton = true;
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {
      _showPlayButton = !_controller.value.isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _controller.setVolume(_isMuted ? 0 : 1);
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      if (_isLiked) {
        await widget.shortsRepository.likeShort(widget.short.id);
      } else {
        await widget.shortsRepository.unlikeShort(widget.short.id);
      }
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked; // Revert on error
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _shareShort() async {
    try {
      await widget.shortsRepository.shareShort(widget.short.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Short shared!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video player
        if (_controller.value.isInitialized)
          GestureDetector(
            onTap: _togglePlay,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),

        // Play/pause overlay
        if (_showPlayButton)
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

        // Top gradient and author info
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.short.authorAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.short.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.short.caption != null)
                        Text(
                          widget.short.caption!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom gradient and controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    if (widget.short.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: widget.short.tags
                            .take(3)
                            .map(
                              (tag) => Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    // Caption
                    if (widget.short.caption != null &&
                        widget.short.caption!.isNotEmpty)
                      Text(
                        widget.short.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right side controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like button
              _ControlButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: widget.short.likeCount.toString(),
                onPressed: _toggleLike,
                color: _isLiked ? Colors.red : Colors.white,
              ),
              const SizedBox(height: 16),
              // Comment button
              _ControlButton(
                icon: Icons.message_rounded,
                label: widget.short.commentCount.toString(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comments feature coming soon!'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Share button
              _ControlButton(
                icon: Icons.share_rounded,
                label: widget.short.shareCount.toString(),
                onPressed: _shareShort,
              ),
              const SizedBox(height: 16),
              // Mute button
              _ControlButton(
                icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                label: '',
                onPressed: _toggleMute,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
