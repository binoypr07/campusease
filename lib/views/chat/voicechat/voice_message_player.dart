import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String voiceUrl;
  final int duration;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.voiceUrl,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;

  late final List<double> _barHeights;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _btnScaleCtrl;

  double? _dragProgress;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);
    _barHeights = _buildBarHeights(42);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..repeat(reverse: true);

    _btnScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    _setupAudioPlayer();
  }

  List<double> _buildBarHeights(int count) {
    final rng = math.Random(widget.voiceUrl.hashCode ^ widget.duration);
    return List.generate(count, (i) {
      final center = count / 2.0;
      final envelope =
          1.0 - math.pow((i - center) / center, 2).toDouble() * 0.38;
      final raw = rng.nextDouble() * 0.55 + 0.32;
      return (raw * envelope).clamp(0.18, 1.0);
    });
  }

  void _setupAudioPlayer() {
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });

    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => _totalDuration = dur);
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _btnScaleCtrl.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      // Set playing state immediately so the button UI reacts instantly
      setState(() => _isPlaying = true);
      try {
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setUrl(widget.voiceUrl);
        }
        await _audioPlayer.play();
      } catch (e) {
        if (mounted) {
          setState(() => _isPlaying = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to play audio')));
        }
      }
    }
  }

  Future<void> _seekToFraction(double fraction) async {
    final ms = (_totalDuration.inMilliseconds * fraction.clamp(0.0, 1.0))
        .round();
    await _audioPlayer.seek(Duration(milliseconds: ms));
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_dragProgress != null) return _dragProgress!;
    final total = _totalDuration.inMilliseconds;
    if (total <= 0) return 0.0;
    return (_currentPosition.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Color get _accent =>
      widget.isMe ? const Color(0xFF4DD0E1) : const Color(0xFF81C784);
  Color get _dim => _accent.withOpacity(0.25);
  Color get _btnBg => widget.isMe
      ? Colors.white.withOpacity(0.18)
      : Colors.white.withOpacity(0.12);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPlayButton(),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWaveform(),
                const SizedBox(height: 3),
                _buildTimerRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Smooth, bouncy play button with icon rotation transition
  Widget _buildPlayButton() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _btnScaleCtrl, curve: Curves.elasticOut),
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: _isPlaying ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack, // Smooth overshoot effect
          builder: (_, t, __) {
            final bgColor = Color.lerp(_btnBg, _accent, t)!;
            final iconColor = Color.lerp(_accent, Colors.white, t)!;
            return AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final glow = t * _pulseCtrl.value * 0.45;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(t * (0.28 + glow * 0.35)),
                        blurRadius: t * (10 + glow * 8),
                        spreadRadius: t * (1 + glow * 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) {
                      // Custom transition: Rotate + Scale for extra smoothness
                      return RotationTransition(
                        turns: Tween<double>(
                          begin: 0.7,
                          end: 1.0,
                        ).animate(anim),
                        child: ScaleTransition(scale: anim, child: child),
                      );
                    },
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(_isPlaying), // Key triggers the animation
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return GestureDetector(
          onTapDown: (d) {
            final f = (d.localPosition.dx / totalWidth).clamp(0.0, 1.0);
            setState(() => _dragProgress = f);
            _seekToFraction(f).then((_) {
              if (mounted) setState(() => _dragProgress = null);
            });
          },
          onHorizontalDragUpdate: (d) {
            final f = (d.localPosition.dx / totalWidth).clamp(0.0, 1.0);
            setState(() => _dragProgress = f);
          },
          onHorizontalDragEnd: (_) {
            if (_dragProgress != null) {
              _seekToFraction(_dragProgress!).then((_) {
                if (mounted) setState(() => _dragProgress = null);
              });
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_shimmerCtrl, _pulseCtrl]),
            builder: (_, __) {
              final count = _barHeights.length;
              return SizedBox(
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(count, (i) {
                    final barFrac = i / (count - 1);
                    final isPast = barFrac <= _progress;
                    double shimmerBump = 0.0;
                    if (!_isPlaying && _dragProgress == null) {
                      final dist = (barFrac - _shimmerCtrl.value).abs();
                      shimmerBump =
                          (1.0 - (dist / 0.10).clamp(0.0, 1.0)) * 0.26;
                    }
                    double pulseBump = 0.0;
                    if (_isPlaying) {
                      final dist = (barFrac - _progress).abs();
                      pulseBump =
                          (1.0 - (dist / 0.08).clamp(0.0, 1.0)) *
                          _pulseCtrl.value *
                          0.40;
                    }
                    final h =
                        (_barHeights[i] + shimmerBump + pulseBump).clamp(
                          0.14,
                          1.0,
                        ) *
                        32;
                    final isScrubHead =
                        _dragProgress != null &&
                        (barFrac - _dragProgress!).abs() < 0.035;
                    Color barColor;
                    if (isScrubHead) {
                      barColor = Colors.white;
                    } else if (isPast) {
                      barColor = _accent;
                    } else {
                      barColor = Color.lerp(_dim, _accent, shimmerBump * 3.2)!;
                    }
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      width: 3.0,
                      height: h,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimerRow() {
    final display = (_isPlaying || _progress > 0)
        ? _formatDuration(_currentPosition)
        : _formatDuration(_totalDuration);

    return Row(
      children: [
        Text(
          display,
          style: TextStyle(
            color: Colors.white.withOpacity(0.52),
            fontSize: 10.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 0.3,
          ),
        ),
        if (_isPlaying) ...[
          const SizedBox(width: 5),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Opacity(
              opacity: 0.35 + _pulseCtrl.value * 0.65,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
