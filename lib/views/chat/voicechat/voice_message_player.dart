import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
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

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        setState(() => _isLoading = true);

        // Load audio if not loaded
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setUrl(widget.voiceUrl);
          final duration = _audioPlayer.duration;
          if (duration != null) {
            setState(() => _totalDuration = duration);
          }
        }

        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to play audio')));
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white24 : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),

        const SizedBox(width: 8),

        // Waveform visualization
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform bars
              SizedBox(
                height: 30,
                child: CustomPaint(
                  painter: WaveformPainter(
                    progress: progress,
                    isPlaying: _isPlaying,
                    color: widget.isMe ? Colors.white70 : Colors.white60,
                    progressColor: widget.isMe
                        ? Colors.white
                        : Colors.blueAccent,
                  ),
                  size: const Size(double.infinity, 30),
                ),
              ),

              const SizedBox(height: 2),

              // Duration text
              Text(
                _isPlaying
                    ? _formatDuration(_currentPosition)
                    : _formatDuration(_totalDuration),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(width: 4),
      ],
    );
  }
}

// Waveform painter for visual representation
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final Color progressColor;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Generate waveform bars (simulated)
    final barCount = 40;
    final barWidth = size.width / barCount;
    final heights = _generateWaveformHeights(barCount);

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final barProgress = i / barCount;

      // Determine color based on progress
      paint.color = barProgress <= progress ? progressColor : color;

      final barHeight = heights[i] * size.height;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  List<double> _generateWaveformHeights(int count) {
    // Simulate waveform pattern
    return List.generate(count, (index) {
      final normalized = index / count;
      final sine = 0.5 + 0.5 * math.sin(normalized * 6.28318);
      final variation = (index % 3) * 0.15;
      return (0.3 + sine * 0.5 + variation).clamp(0.2, 1.0);
    });
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
