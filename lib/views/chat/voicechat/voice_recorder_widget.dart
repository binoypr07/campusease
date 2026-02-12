import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VoiceRecorderWidget extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String path, int duration) onSend;

  const VoiceRecorderWidget({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _timer;
  int _recordDuration = 0;
  bool _isRecording = false;
  bool _isStopping = false;

  double _dragOffset = 0;
  final double _cancelThreshold = -80.0; // Slightly shorter for better UX

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startRecording();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        _recordDuration = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordDuration++);
          }
        });

        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('START ERROR: $e');
      widget.onCancel();
    }
  }

  Future<void> _stopAndAction(bool shouldSend) async {
    if (_isStopping) return;
    _isStopping = true;

    _timer?.cancel();

    try {
      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);

      if (shouldSend && path != null && _recordDuration > 0) {
        widget.onSend(path, _recordDuration);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint("STOP ERROR: $e");
      widget.onCancel();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // We wrap in a WillPopScope-like logic or just ensure it fills width
    return Container(
      width: double.infinity, // Constrain width to parent
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // 1. Delete/Cancel Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white54, size: 24),
            onPressed: () => _stopAndAction(false),
          ),

          // 2. Main Recording Body (The swipable part)
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                  if (_dragOffset > 0) _dragOffset = 0;

                  // Trigger haptic at threshold
                  if (_dragOffset < _cancelThreshold &&
                      _dragOffset > _cancelThreshold - 2) {
                    HapticFeedback.lightImpact();
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragOffset < _cancelThreshold) {
                  _stopAndAction(false);
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              child: ClipRRect(
                // Ensures the translate doesn't paint outside bounds
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3942),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: const Icon(
                            Icons.mic,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_recordDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        // Fixed: Opacity calculation is now more robust
                        Opacity(
                          opacity: (1.0 + (_dragOffset / 60)).clamp(0.0, 1.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.arrow_back_ios,
                                size: 12,
                                color: Colors.white38,
                              ),
                              Text(
                                "Slide to cancel",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 3. Send Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _stopAndAction(true);
            },
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF00A884),
              child: Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
