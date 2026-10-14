import 'package:flutter/material.dart';

import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/stop_tile.dart';

/// Bottom-sheet stop picker used by the route finder.
Future<StopGroup?> showStopPicker(BuildContext context) {
  return showModalBottomSheet<StopGroup>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (_) => const _StopPickerSheet(),
  );
}

class _StopPickerSheet extends StatefulWidget {
  const _StopPickerSheet();

  @override
  State<_StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends State<_StopPickerSheet> {
  List<StopGroup>? _groups;
  String _query = '';

  @override
  void initState() {
    super.initState();
    StopsService.all().then((stops) {
      if (mounted) setState(() => _groups = StopsService.grouped(stops));
    }).catchError((_) {
      if (mounted) setState(() => _groups = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _groups == null
        ? <StopGroup>[]
        : StopsService.search(_groups!, _query);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scegli una fermata',
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cerca stazione...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _groups == null
                  ? const LoadingView()
                  : filtered.isEmpty
                      ? Center(
                          child: Text('Nessuna stazione trovata.',
                              style: TextStyle(color: context.muted)))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => StopTile(
                            group: filtered[i],
                            onTap: () => Navigator.pop(context, filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
