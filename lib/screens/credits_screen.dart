import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';

/// Port of `/credits` — attributions and licenses.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: context.l10n.moreCredits,
              subtitle: context.l10n.creditsSubtitle,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _card(context, context.l10n.mapsCredit, [
                  _link(context, 'OpenStreetMap contributors',
                      'https://www.openstreetmap.org/copyright',
                      context.l10n.mapDataOdbL),
                  _link(context, 'Nominatim',
                      'https://nominatim.org/', context.l10n.geocodingNote),
                ]),
                const SizedBox(height: 16),
                _card(context, context.l10n.transitData, [
                  _link(context, 'ACTV open data',
                      'https://actv.avmspa.it/',
                      context.l10n.transitDataNote),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l10n.unofficialProject,
                      style: TextStyle(color: context.muted, fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _card(context, context.l10n.openSourceLibs, [
                  _lib(context, 'Flutter', 'BSD-3-Clause'),
                  _lib(context, 'flutter_map', 'BSD-3-Clause'),
                  _lib(context, 'OpenStreetMap tiles', '© OSM contributors'),
                  _lib(context, 'qr_flutter', 'BSD-3-Clause'),
                  _lib(context, 'google_fonts (Inter)', 'OFL-1.1'),
                  _lib(context, 'shared_preferences', 'BSD-3-Clause'),
                  _lib(context, 'geolocator', 'MIT'),
                  _lib(context, 'http', 'BSD-3-Clause'),
                  _lib(context, 'intl', 'BSD-3-Clause'),
                ]),
                const SizedBox(height: 16),
                _card(context, context.l10n.project, [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: context.muted, fontSize: 14),
                      children: [
                        TextSpan(
                            text: context.l10n.creditsReleasedBy),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse(
                                'https://github.com/samuele-brusegan')),
                            child: Text('Samuele Brusegan',
                                style: TextStyle(
                                    color: context.blue,
                                    decoration:
                                        TextDecoration.underline)),
                          ),
                        ),
                        TextSpan(text: context.l10n.creditsDesignBy),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse(
                                'https://github.com/andreadavanzo09-bit')),
                            child: Text('Andrea Davanzo',
                                style: TextStyle(
                                    color: context.blue,
                                    decoration:
                                        TextDecoration.underline)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String title, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          ...children,
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, String url, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(url)),
              child: Text(
                label,
                style: TextStyle(
                  color: context.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(note, style: TextStyle(color: context.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _lib(BuildContext context, String name, String license) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: context.ink, fontWeight: FontWeight.w600)),
          ),
          Text(license,
              style: TextStyle(color: context.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
