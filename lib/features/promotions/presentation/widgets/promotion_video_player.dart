import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PromotionVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;

  const PromotionVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
  });

  @override
  State<PromotionVideoPlayer> createState() => _PromotionVideoPlayerState();
}

class _PromotionVideoPlayerState extends State<PromotionVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

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
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Muted for homepage carousel
        if (widget.isPlaying) {
          _controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
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
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
