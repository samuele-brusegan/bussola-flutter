import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Colored line badge, matching `.line-badge`.
class LineBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final bool large;

  const LineBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color ?? context.blue,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: large ? 18 : 14,
          height: 1.15,
        ),
      ),
    );
  }
}

/// Small stop-id badge, matching `.id-badge-small`.
class StopIdBadge extends StatelessWidget {
  final String id;
  const StopIdBadge({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 45),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.blue,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        id,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
