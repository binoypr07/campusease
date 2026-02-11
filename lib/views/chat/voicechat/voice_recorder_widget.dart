import 'dart:async';
import 'package:flutter/material.dart';
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
  String? _audioPath;
  bool _isRecording = false;

  // For the "Slide to Cancel" interaction
  double _dragOffset = 0;
  final double _cancelThreshold = -100.0;

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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // 1. Check Permission
      if (await _audioRecorder.hasPermission()) {
        String path;
        if (kIsWeb) {
          path = '';
        } else {
          // App Internal Directory is best for Android 11+
          final dir = await getApplicationDocumentsDirectory();
          path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        // 2. Start the recording engine
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        // 3. START THE TIMER (The missing piece!)
        _recordDuration = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });

        setState(() {
          _audioPath = path;
          _isRecording = true;
        });

        debugPrint("DEBUG: Recording started at $path");
      }
    } catch (e) {
      debugPrint('DEBUG ERROR: $e');
      widget.onCancel(); // Close UI if error occurs
    }
  }

  Future<void> _stopAndAction(bool shouldSend) async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (shouldSend && path != null && _recordDuration > 0) {
      widget.onSend(path, _recordDuration);
    } else {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Delete Icon
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white54),
            onPressed: () => _stopAndAction(false),
          ),

          // Sliding Recording Area
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                  if (_dragOffset > 0) _dragOffset = 0; // Prevent sliding right
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragOffset < _cancelThreshold) {
                  _stopAndAction(false); // Cancel if swiped far enough
                } else {
                  setState(() => _dragOffset = 0); // Reset position
                }
              },
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3942),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: const Icon(
                          Icons.mic,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDuration(_recordDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // Fade out text as user slides
                      Opacity(
                        opacity: (1.0 + (_dragOffset / 100)).clamp(0.0, 1.0),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios,
                              size: 12,
                              color: Colors.white38,
                            ),
                            Text(
                              "Slide to cancel",
                              style: TextStyle(color: Colors.white38),
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

          const SizedBox(width: 10),

          // Send Button
          GestureDetector(
            onTap: () => _stopAndAction(true),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF00A884), // WhatsApp green
              child: Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
