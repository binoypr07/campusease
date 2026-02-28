import 'dart:html' as html;

/// Opens a file URL in a new browser tab.
/// Works for cross-origin Cloudinary URLs where the `download`
/// attribute is ignored by browsers due to CORS policy.
void downloadUrlOnWeb(String url, String fileName) {
  html.window.open(url, '_blank');
}

/// Kept for API compatibility — not used on web
void downloadFileOnWeb(List<int> bytes, String fileName) {}
