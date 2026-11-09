import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

import '../screens/privacy_screen.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// GDPR cookie-consent bottom bar — port of `cookie-notice.js`
/// (`cookie_consent_accepted` key, "Scopri di più" → privacy).
class CookieBanner extends StatefulWidget {
  final Widget child;
  const CookieBanner({super.key, required this.child});

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!await Storage.getBool(Storage.cookieConsent)) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300),
            () => mounted ? setState(() => _visible = true) : null);
      }
    }
  }

  Future<void> _accept() async {
    await Storage.setBool(Storage.cookieConsent, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: context.surface,
              elevation: 16,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cookie & Privacy',
                          style: TextStyle(
                              color: context.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                              color: context.muted, fontSize: 13),
                          children: [
                            TextSpan(
                                text: context.l10n.cookieBannerText),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PrivacyScreen()),
                                ),
                                child: Text(context.l10n.cookieLearnMore,
                                    style: TextStyle(
                                        color: context.blue,
                                        decoration:
                                            TextDecoration.underline)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _accept,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40)),
                          child: Text(context.l10n.cookieAccept),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Red offline indicator bar — port of `.offline-indicator`.
class OfflineIndicator extends StatefulWidget {
  final Widget child;
  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    _sub = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (offline != _offline && mounted) {
      setState(() => _offline = offline);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          Container(
            width: double.infinity,
            color: const Color(0xFFE30613),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n.youAreOffline,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
