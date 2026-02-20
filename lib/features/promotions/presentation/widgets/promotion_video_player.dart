import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

class PromotionVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isPlaying;

  const PromotionVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isPlaying,
  });

  @override
  State<PromotionVideoPlayer> createState() => _PromotionVideoPlayerState();
}

class _PromotionVideoPlayerState extends State<PromotionVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        _controller.setLooping(true);
        _controller.setVolume(_isMuted ? 0.0 : 1.0);
        if (widget.isPlaying) {
          _controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(PromotionVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isPlaying && !oldWidget.isPlaying) {
        _controller.play();
      } else if (!widget.isPlaying && oldWidget.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Thumbnail / Placeholder (Always at the bottom)
        if (widget.thumbnailUrl != null)
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[900],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.white24,
              ),
            ),
          )
        else
          Container(color: Colors.grey[900]),

        // 2. Video Player
        if (_isInitialized && !_hasError)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

        // 3. Loading overlay
        if (!_isInitialized && !_hasError)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),

        // 4. Error overlay
        if (_hasError)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),

        // 5. Mute/Unmute Toggle
        if (_isInitialized && !_hasError)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                  _controller.setVolume(_isMuted ? 0.0 : 1.0);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

        // 6. Buffering indicator
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, VideoPlayerValue value, child) {
            if (value.isBuffering && _isInitialized && !_hasError) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
