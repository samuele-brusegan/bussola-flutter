import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Green gradient header with the diagonal bottom edge, matching
/// `.header-green` in the web app.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final bool compact;
  final List<Widget>? actions;
  final String? brand;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.compact = false,
    this.actions,
    this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final top = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: _DiagonalClipper(cut: 38),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF0E5A3C), Color(0xFF15935E)]
                : const [AppColors.lightGreenDark, AppColors.lightGreen],
          ),
        ),
        padding: EdgeInsets.only(
          top: top + 14,
          left: 20,
          right: 20,
          bottom: compact ? 52 : 58,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CircleBackButton(onTap: () => Navigator.maybePop(context)),
                  ),
                if (brand != null && !showBack)
                  Text(
                    brand!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                const Spacer(),
                ...?actions,
              ],
            ),
            SizedBox(height: showBack ? 12 : 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                height: 1.08,
                letterSpacing: -0.8,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

/// Toggle button for light/dark theme, matching `.theme-button`.
class ThemeToggleButton extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeToggleButton({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final darkActive = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onChanged(darkActive ? ThemeMode.light : ThemeMode.dark),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            darkActive ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  final double cut;
  const _DiagonalClipper({required this.cut});

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height)
    ..lineTo(size.width, size.height - cut)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_DiagonalClipper old) => old.cut != cut;
}
