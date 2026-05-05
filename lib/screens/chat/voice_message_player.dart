import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/theme.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final int duration;
  const VoiceMessagePlayer({super.key, required this.url, required this.duration});
  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _playing     = false;
  late AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _initCtrl();
  }

  Future<void> _initCtrl() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize().timeout(const Duration(seconds: 20));
      c.addListener(() { if (mounted) setState(() => _playing = c.value.isPlaying); });
      if (mounted) setState(() { _ctrl = c; _initialized = true; });
    } catch (_) {}
  }

  @override
  void dispose() { _wave.dispose(); _ctrl?.dispose(); super.dispose(); }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Row(children: [
      GestureDetector(
        onTap: () { if (!_initialized) return; _playing ? _ctrl!.pause() : _ctrl!.play(); },
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle),
          child: Icon(
            _initialized ? (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded) : Icons.hourglass_bottom_rounded,
            color: Colors.white, size: 22),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedBuilder(
          animation: _wave,
          builder: (_, __) => SizedBox(
            height: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(18, (i) {
                final h = _playing
                    ? (5 + 14 * (0.5 + 0.5 * math.sin(_wave.value * math.pi * 2 + i * 0.5))).clamp(3.0, 20.0)
                    : (i % 3 == 0 ? 14.0 : i % 2 == 0 ? 7.0 : 10.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 2.2, height: h,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(_playing ? 0.9 : 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 3),
        ValueListenableBuilder(
          valueListenable: _ctrl ?? _dummyNotifier(),
          builder: (_, val, __) {
            final v  = val as VideoPlayerValue;
            final pos = _initialized ? v.position.inSeconds : 0;
            final dur = _initialized ? v.duration.inSeconds : widget.duration;
            return Text(
              _initialized ? '${_fmt(pos)} / ${_fmt(dur)}' : _fmt(widget.duration),
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
            );
          },
        ),
      ])),
    ]),
  );

  ValueNotifier<VideoPlayerValue> _dummyNotifier() =>
      ValueNotifier(VideoPlayerValue(duration: Duration(seconds: widget.duration)));
}
