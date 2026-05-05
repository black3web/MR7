import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/theme.dart';

class VideoMessagePlayer extends StatefulWidget {
  final String url;
  const VideoMessagePlayer({super.key, required this.url});
  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _playing = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize().timeout(const Duration(seconds: 20));
      c.addListener(() {
        if (mounted) setState(() => _playing = c.value.isPlaying);
      });
      if (mounted) setState(() { _ctrl = c; _initialized = true; });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_error) return Container(
      width: 220, height: 140, decoration: BoxDecoration(
        color: AppColors.bgLight, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.videocam_off_rounded, color: AppColors.textMuted),
        SizedBox(height: 4),
        Text('تعذر تحميل الفيديو', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ])),
    );

    if (!_initialized) return Container(
      width: 220, height: 140, decoration: BoxDecoration(
        color: AppColors.bgLight, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 220,
        child: AspectRatio(
          aspectRatio: _ctrl!.value.aspectRatio.clamp(0.5, 2.5),
          child: Stack(children: [
            VideoPlayer(_ctrl!),
            Positioned.fill(child: GestureDetector(
              onTap: () => _playing ? _ctrl!.pause() : _ctrl!.play(),
              child: AnimatedOpacity(
                opacity: _playing ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black45,
                  child: const Center(child: Icon(Icons.play_circle_fill_rounded, size: 48, color: Colors.white)),
                ),
              ),
            )),
            Positioned(bottom: 0, left: 0, right: 0,
              child: VideoProgressIndicator(_ctrl!, allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.accent,
                  bufferedColor: AppColors.primary.withOpacity(0.4),
                  backgroundColor: Colors.white12,
                ))),
          ]),
        ),
      ),
    );
  }
}
