import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Slim solid-green header bar — matches the compact `.header-green` used by
/// the web app's map/schedule pages: back arrow, title, optional subtitle.
class SlimHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;

  const SlimHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: context.isDark
          ? const Color(0xFF0E5A3C)
          : AppColors.lightGreen,
      padding: EdgeInsets.fromLTRB(12, top + 10, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: showBack
                ? InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.maybePop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: subtitle == null
                ? Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
          ...?actions,
          if (actions == null) const SizedBox(width: 36),
        ],
      ),
    );
  }
}
