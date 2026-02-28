// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// On web — creates an invisible anchor with the URL and clicks it.
/// This lets the browser handle the download directly (no CORS issues).
void downloadFileOnWeb(List<int> bytes, String fileName) {
  // bytes param kept for API compatibility but not used on web
  // We never get here — use downloadUrlOnWeb instead for web
}

/// Triggers a browser download using a direct URL (no CORS fetch needed).
/// Works for Cloudinary raw files, PDFs, images, videos — anything with a public URL.
void downloadUrlOnWeb(String url, String fileName) {
  final anchor = html.AnchorElement()
    ..href = url
    ..setAttribute('download', fileName)
    ..setAttribute(
      'target',
      '_blank',
    ) // fallback: open in new tab if download blocked
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
