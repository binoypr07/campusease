import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'helpers/download_helper.dart';

class MediaViewerPage extends StatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image' | 'video' | 'pdf' | 'file'
  final String senderName;
  final String? fileName;
  final DateTime? timestamp;

  const MediaViewerPage({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.senderName,
    this.fileName,
    this.timestamp,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;
  bool _showControls = true;

  final TransformationController _transformController =
      TransformationController();

  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _savedFilePath = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 0.82,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    if (widget.mediaType == 'video') _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaUrl),
    );
    _videoController = controller;
    try {
      await controller.initialize();
      if (mounted) {
        controller.addListener(() {
          if (mounted) setState(() {});
        });
        setState(() => _videoInitialized = true);
        controller.play();
      }
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _transformController.dispose();
    _pulseController.dispose();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _togglePlayPause() {
    if (_videoController == null) return;
    _pulseController.forward().then((_) => _pulseController.reverse());
    _videoController!.value.isPlaying
        ? _videoController!.pause()
        : _videoController!.play();
  }

  // ─── Permission ────────────────────────────────────────────────────────────
  Future<bool> _requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    if (await Permission.photos.isGranted || await Permission.videos.isGranted)
      return true;
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();
    return photos.isGranted || videos.isGranted;
  }

  // ─── Resolve file name ─────────────────────────────────────────────────────
  String _resolveFileName() {
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!;
    }
    final uri = Uri.parse(widget.mediaUrl);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final last = segments.last;
      if (last.contains('.')) return last;
    }
    final ext = _getExtension();
    return 'campusease_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  String _getExtension() {
    switch (widget.mediaType) {
      case 'image':
        return 'jpg';
      case 'video':
        return 'mp4';
      case 'pdf':
        return 'pdf';
      default:
        final name = widget.fileName ?? '';
        if (name.contains('.')) return name.split('.').last.toLowerCase();
        final url = widget.mediaUrl;
        if (url.contains('.')) {
          return url.split('.').last.split('?').first.toLowerCase();
        }
        return 'pdf';
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  // ─── Main download + open logic ────────────────────────────────────────────
  Future<void> _downloadAndOpen() async {
    // Already downloaded this session — just reopen
    if (!kIsWeb &&
        _savedFilePath.isNotEmpty &&
        await File(_savedFilePath).exists()) {
      await _openWithNativeApp(_savedFilePath);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final fileName = _resolveFileName();

      if (kIsWeb) {
        // ── WEB ──────────────────────────────────────────────────────────────
        // Use direct URL anchor click — no Dio fetch, no CORS issues.
        // The browser handles the download natively.
        downloadUrlOnWeb(widget.mediaUrl, fileName);
        _showSnack('Download started! Check your browser downloads.');
        return;
      }

      // ── MOBILE ───────────────────────────────────────────────────────────
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        _showSnack('Storage permission denied', isError: true);
        return;
      }

      final isMedia =
          widget.mediaType == 'image' || widget.mediaType == 'video';

      final cacheDir = await getTemporaryDirectory();
      final savePath = '${cacheDir.path}/$fileName';

      // Delete stale cached file
      final oldFile = File(savePath);
      if (await oldFile.exists()) await oldFile.delete();

      debugPrint('⬇️  Downloading: ${widget.mediaUrl}');
      debugPrint('💾  Saving to: $savePath');

      await Dio().download(
        widget.mediaUrl,
        savePath,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      // Verify download
      final savedFile = File(savePath);
      if (!await savedFile.exists() || await savedFile.length() == 0) {
        _showSnack('Download failed — file is empty', isError: true);
        return;
      }

      debugPrint(' File size: ${await savedFile.length()} bytes');
      setState(() => _savedFilePath = savePath);

      // REPLACE WITH THIS:
      if (isMedia) {
        try {
          if (widget.mediaType == 'video') {
            await Gal.putVideo(savePath);
          } else {
            await Gal.putImage(savePath);
          }
          _showSnack('Saved to gallery!');
        } catch (e) {
          _showSnack('Failed to save to gallery: $e', isError: true);
        }
      } else {
        await _openWithNativeApp(savePath);
      }
    } catch (e) {
      debugPrint('  Download error: $e');
      _showSnack('Download failed: $e', isError: true);
    } finally {
      if (mounted)
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
    }
  }

  Future<void> _openWithNativeApp(String filePath) async {
    final ext = _getExtension();
    final mimeType = _getMimeType(ext);

    debugPrint('📂  Opening: $filePath');
    debugPrint('🗂️  MIME: $mimeType');

    final result = await OpenFilex.open(filePath, type: mimeType);
    debugPrint('📋  Result: ${result.type} — ${result.message}');

    switch (result.type) {
      case ResultType.done:
        break; // success — no snack needed
      case ResultType.noAppToOpen:
        _showSnack(
          'No app found to open .$ext files.\nInstall a PDF reader or file manager.',
          isError: true,
        );
        break;
      case ResultType.permissionDenied:
        _showSnack('Permission denied to open file', isError: true);
        break;
      case ResultType.fileNotFound:
        _showSnack('File not found — try downloading again', isError: true);
        setState(() => _savedFilePath = '');
        break;
      case ResultType.error:
        _showSnack('Could not open: ${result.message}', isError: true);
        break;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF00A884),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: GestureDetector(
                onTap: widget.mediaType == 'video' ? _toggleControls : null,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.mediaType == 'video'
                        ? _buildVideoPlayer()
                        : widget.mediaType == 'image'
                        ? _buildImageViewer()
                        : _buildFilePreview(),
                    if (widget.mediaType == 'video' &&
                        _videoInitialized &&
                        _showControls)
                      _buildCenterPlayButton(),
                  ],
                ),
              ),
            ),
            if (widget.mediaType == 'video' &&
                _videoInitialized &&
                _showControls)
              _buildBottomControls(),
            if (_isDownloading) _buildDownloadBar(),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final isFile = widget.mediaType == 'pdf' || widget.mediaType == 'file';
    return Container(
      color: const Color(0xFF1F2C34),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (widget.timestamp != null)
                  Text(
                    _formatDate(widget.timestamp!),
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
              ],
            ),
          ),
          _isDownloading
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isFile ? Icons.open_in_new_rounded : Icons.download_rounded,
                    color: Colors.white,
                  ),
                  tooltip: isFile ? 'Open with app' : 'Save to gallery',
                  onPressed: _downloadAndOpen,
                ),
        ],
      ),
    );
  }

  // ─── Center play/pause ─────────────────────────────────────────────────────
  Widget _buildCenterPlayButton() {
    final isPlaying = _videoController?.value.isPlaying ?? false;
    return GestureDetector(
      onTap: _togglePlayPause,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }

  // ─── Bottom scrubber ───────────────────────────────────────────────────────
  Widget _buildBottomControls() {
    final controller = _videoController!;
    final value = controller.value;
    final posMs = value.position.inMilliseconds.toDouble();
    final durMs = value.duration.inMilliseconds.toDouble();
    final safeMax = durMs > 0 ? durMs : 1.0;

    return Container(
      color: const Color(0xFF1F2C34),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF00A884),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: posMs.clamp(0.0, safeMax),
              min: 0,
              max: safeMax,
              onChanged: (v) {
                controller.seekTo(Duration(milliseconds: v.toInt()));
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _formatDuration(value.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image viewer ──────────────────────────────────────────────────────────
  Widget _buildImageViewer() {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.8,
      maxScale: 5.0,
      child: Center(
        child: Image.network(
          widget.mediaUrl,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            final pct = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    color: const Color(0xFF00A884),
                  ),
                  if (pct != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${(pct * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white38,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'Could not load image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Video player ──────────────────────────────────────────────────────────
  Widget _buildVideoPlayer() {
    if (_videoError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 64),
            SizedBox(height: 12),
            Text(
              'Could not load video',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }
    if (!_videoInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A884)),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  // ─── File / PDF preview card ───────────────────────────────────────────────
  Widget _buildFilePreview() {
    final isPdf = widget.mediaType == 'pdf';
    final ext = _getExtension();
    final name = _resolveFileName();
    final icon = isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.insert_drive_file_rounded;
    final color = isPdf ? const Color(0xFFE94E4E) : const Color(0xFF5E5CE6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 2),
              ),
              child: Icon(icon, color: color, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                ext.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Click below to download this file'
                  : _savedFilePath.isNotEmpty
                  ? 'File ready — tap to open again'
                  : 'Tap below to open with your device app',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isDownloading ? null : _downloadAndOpen,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        kIsWeb
                            ? Icons.download_rounded
                            : Icons.open_in_new_rounded,
                      ),
                label: Text(
                  _isDownloading
                      ? 'Downloading ${(_downloadProgress * 100).toInt()}%...'
                      : kIsWeb
                      ? 'Download File'
                      : 'Open File',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Download progress bar ─────────────────────────────────────────────────
  Widget _buildDownloadBar() {
    return Container(
      color: const Color(0xFF1F2C34),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download_rounded,
                color: Color(0xFF00A884),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _downloadProgress > 0
                      ? 'Downloading... ${(_downloadProgress * 100).toInt()}%'
                      : 'Preparing...',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              backgroundColor: Colors.white12,
              color: const Color(0xFF00A884),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
