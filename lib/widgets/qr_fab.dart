import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';

/// Green circular FAB (52px) that opens a dialog with a QR code for the
/// given URL — equivalent of the web app's `.qr-fab` + qrcode-generator.
class QrFab extends StatelessWidget {
  /// Page path on the web app (e.g. `/aut/stops/stop?id=1&name=X`).
  /// Defaults to `/`.
  final String url;

  const QrFab({super.key, this.url = '/'});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'qr-fab-$url',
      onPressed: () => showQrDialog(context, url),
      backgroundColor: context.greenDark,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_2, color: Colors.white, size: 26),
    );
  }
}

/// Resolves a page path to a full URL on the configured API server.
String webUrlFor(String path) {
  final base = ApiClient.baseUrl;
  if (path.startsWith('http')) return path;
  return '$base${path.startsWith('/') ? path : '/$path'}';
}

void showQrDialog(BuildContext context, String url) {
  final fullUrl = webUrlFor(url);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ctx.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.l10n.qrOpenOnWeb,
              style: TextStyle(
                color: ctx.ink,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: fullUrl,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              fullUrl,
              textAlign: TextAlign.center,
              style: TextStyle(color: ctx.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullUrl));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(ctx.l10n.linkCopied)),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text(ctx.l10n.copyLink),
            ),
          ],
        ),
      ),
    ),
  );
}
