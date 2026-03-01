import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

typedef OnMediaUploaded =
    void Function(
      String mediaUrl,
      String mediaType, {
      String? thumbnailUrl,
      String? fileName,
      int? fileSize,
    });

class MediaUploaderWidget extends StatefulWidget {
  final OnMediaUploaded onUploaded;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final VoidCallback onChanged;

  const MediaUploaderWidget({
    super.key,
    required this.onUploaded,
    required this.messageController,
    required this.messageFocusNode,
    required this.onChanged,
  });

  @override
  State<MediaUploaderWidget> createState() => _MediaUploaderWidgetState();
}

class _MediaUploaderWidgetState extends State<MediaUploaderWidget> {
  static const String _cloudName = '';
  static const String _uploadPreset = 'my_voice_preset';

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadLabel = '';

  // ─── Image Compression ─────────────────────────────────────────────────────
  Future<XFile?> _compressImage(XFile file) async {
    if (kIsWeb) return file;
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 85,
      minWidth: 1920,
      minHeight: 1080,
      keepExif: false,
    );
    return result != null ? XFile(result.path) : file;
  }

  // ─── Video Compression ─────────────────────────────────────────────────────
  Future<XFile?> _compressVideo(XFile file) async {
    if (kIsWeb) return file;
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 30,
    );
    return (info != null && info.path != null) ? XFile(info.path!) : file;
  }

  // ─── Video Thumbnail ───────────────────────────────────────────────────────
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    if (kIsWeb) return null;
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 640,
      quality: 75,
    );
    return thumbnailPath;
  }

  // ─── Cloudinary Upload ─────────────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(
    XFile file,
    String resourceType, {
    bool isThumbnail = false,
    String? folder,
  }) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['resource_type'] = resourceType;
    if (isThumbnail) request.fields['folder'] = 'thumbnails';
    if (folder != null && !isThumbnail) request.fields['folder'] = folder;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await request.send();
    final int total = streamed.contentLength ?? 0;
    int received = 0;
    final List<int> bodyBytes = [];

    await for (final chunk in streamed.stream) {
      bodyBytes.addAll(chunk);
      received += chunk.length;
      if (!isThumbnail && total > 0 && mounted) {
        setState(() => _uploadProgress = received / total);
      }
    }

    if (streamed.statusCode == 200) {
      final data = jsonDecode(utf8.decode(bodyBytes));
      return data['secure_url'] as String?;
    } else {
      final errorData = jsonDecode(utf8.decode(bodyBytes));
      _showError(
        'Upload failed: ${errorData['error']?['message'] ?? streamed.statusCode}',
      );
      return null;
    }
  }

  // ─── Pick Image / Video ────────────────────────────────────────────────────
  Future<void> _pickAndUpload(ImageSource source, String mediaType) async {
    Navigator.pop(context);

    final picker = ImagePicker();
    XFile? file;

    try {
      if (mediaType == 'image') {
        file = await picker.pickImage(source: source, imageQuality: 90);
      } else {
        file = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );
      }
    } catch (e) {
      _showError('Could not pick file: $e');
      return;
    }

    if (file == null) return;

    // Read original size before compression
    final originalBytes = await file.readAsBytes();
    final originalSize = originalBytes.length;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadLabel = mediaType == 'image'
          ? 'Uploading photo...'
          : 'Compressing video...';
    });

    try {
      XFile fileToUpload = file;
      String? thumbnailPath;

      if (mediaType == 'image') {
        fileToUpload = await _compressImage(file) ?? file;
      } else {
        thumbnailPath = await _generateVideoThumbnail(file.path);
        if (mounted) setState(() => _uploadLabel = 'Uploading video...');
        fileToUpload = await _compressVideo(file) ?? file;
      }

      final String? mediaUrl = await _uploadToCloudinary(
        fileToUpload,
        mediaType == 'video' ? 'video' : 'image',
      );
      if (mediaUrl == null) return;

      String? thumbnailUrl;
      if (mediaType == 'video' && thumbnailPath != null) {
        thumbnailUrl = await _uploadToCloudinary(
          XFile(thumbnailPath),
          'image',
          isThumbnail: true,
        );
      }

      widget.onUploaded(
        mediaUrl,
        mediaType,
        thumbnailUrl: thumbnailUrl,
        fileSize: originalSize,
      );
    } catch (e) {
      _showError('Upload error: $e');
    } finally {
      if (mediaType == 'video' && !kIsWeb) {
        await VideoCompress.deleteAllCache();
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Pick and Upload File / PDF ────────────────────────────────────────────
  Future<void> _pickAndUploadFile(String fileCategory) async {
    Navigator.pop(context);

    FilePickerResult? result;
    try {
      if (fileCategory == 'pdf') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'ppt',
            'pptx',
            'txt',
            'csv',
            'zip',
          ],
          withData: true,
        );
      }
    } catch (e) {
      _showError('Could not pick file: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final originalName = pickedFile.name;
    final fileSize = pickedFile.size; // raw bytes for WhatsApp-style display

    if (fileSize > 20 * 1024 * 1024) {
      _showError('File too large (max 20 MB)');
      return;
    }

    final fileBytes = pickedFile.bytes;
    if (fileBytes == null || fileBytes.isEmpty) {
      _showError('Could not read file bytes');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadLabel = 'Uploading $originalName...';
    });

    try {
      final xfile = XFile.fromData(fileBytes, name: originalName);

      final String? fileUrl = await _uploadToCloudinary(
        xfile,
        'raw',
        folder: 'documents',
      );

      if (fileUrl == null) return;

      final ext = originalName.split('.').last.toLowerCase();
      final messageType = ext == 'pdf' ? 'pdf' : 'file';

      widget.onUploaded(
        fileUrl,
        messageType,
        fileName: originalName,
        fileSize: fileSize,
      );
    } catch (e) {
      _showError('Upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  // ─── WhatsApp-style Attach Bottom Sheet ────────────────────────────────────
  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: const Color(0xFF5E5CE6),
                    onTap: () => _pickAndUploadFile('document'),
                  ),
                  _AttachOption(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    color: const Color(0xFFE94E4E),
                    onTap: () => _pickAndUploadFile('pdf'),
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF00A884),
                    onTap: () => _pickAndUpload(ImageSource.gallery, 'image'),
                  ),
                  _AttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFFFF9500),
                    onTap: () => _pickAndUpload(ImageSource.camera, 'image'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachOption(
                    icon: Icons.video_library_rounded,
                    label: 'Video',
                    color: const Color(0xFF007AFF),
                    onTap: () => _pickAndUpload(ImageSource.gallery, 'video'),
                  ),
                  _AttachOption(
                    icon: Icons.videocam_rounded,
                    label: 'Record',
                    color: const Color(0xFFFF2D55),
                    onTap: () => _pickAndUpload(ImageSource.camera, 'video'),
                  ),
                  const SizedBox(width: 64),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Attach button ──────────────────────────────────────────────────
        GestureDetector(
          onTap: _isUploading ? null : _showAttachSheet,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              color: Color(0xFF2A3942),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_file_rounded,
              color: Colors.white54,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // ── Text field ─────────────────────────────────────────────────────
        // suffixIcon = upload spinner while uploading, null otherwise.
        // The download icon has been REMOVED — it belongs only in the viewer.
        Expanded(
          child: TextField(
            controller: widget.messageController,
            focusNode: widget.messageFocusNode,
            onChanged: (_) => widget.onChanged(),
            maxLines: 5,
            minLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: _isUploading ? _uploadLabel : 'Type a message...',
              hintStyle: TextStyle(
                color: _isUploading ? const Color(0xFF00A884) : Colors.white38,
                fontSize: _isUploading ? 13 : 16,
              ),
              filled: true,
              fillColor: const Color(0xFF2A3942),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isUploading
                  ? SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            strokeWidth: 2.5,
                            color: const Color(0xFF00A884),
                          ),
                          if (_uploadProgress > 0)
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Attach Option Tile ────────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _PickerTile (kept for backward compat) ───────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A884)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
