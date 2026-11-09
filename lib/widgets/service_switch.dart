import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Two-button icon service switch (bus / vaporetto), matching the web app's
/// `.service-switch`. Modes: 'both', 'automobilistico', 'navigation'.
/// Tapping a button while in 'both' leaves only the other service;
/// tapping the inactive single returns to 'both'.
class ServiceSwitch extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;
  final bool allowBoth;

  const ServiceSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
    this.allowBoth = true,
  });

  bool _active(String service) =>
      allowBoth ? (mode == 'both' || mode == service) : mode == service;

  void _tap(String service) {
    if (!allowBoth) {
      onChanged(service);
      return;
    }
    onChanged(switch (mode) {
      'both' =>
        service == 'navigation' ? 'automobilistico' : 'navigation',
      _ => mode == service ? mode : 'both',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, Icons.directions_bus, 'automobilistico'),
          Container(width: 1, height: 24, color: context.border),
          _btn(context, Icons.directions_boat, 'navigation'),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String service) {
    final active = _active(service);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _tap(service),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon,
          size: 20,
          color: active ? context.blue : context.muted,
        ),
      ),
    );
  }
}
