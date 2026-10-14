import 'package:flutter/material.dart';

import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/stop_tile.dart';
import 'stop_detail_screen.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  List<StopGroup>? _groups;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final stops = await StopsService.all(forceRefresh: _groups != null);
      if (!mounted) return;
      setState(() => _groups = StopsService.grouped(stops));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _groups == null
        ? <StopGroup>[]
        : StopsService.search(_groups!, _query);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(title: 'Tutte le\nStazioni'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cerca stazione...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          if (_error != null)
            SliverFillRemaining(
              child: ErrorView(error: _error!, onRetry: _load),
            )
          else if (_groups == null)
            const SliverFillRemaining(child: LoadingView())
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Nessuna stazione trovata.',
                    style: TextStyle(color: context.muted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => StopTile(
                    group: filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StopDetailScreen(group: filtered[i]),
                      ),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
