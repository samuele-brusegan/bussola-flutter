import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';

/// Equivalent of the web app's "delete cookie" page plus API base URL
/// configuration.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _urlController = TextEditingController(text: ApiClient.baseUrl);

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    final keepUrl = prefs.getString('api_base_url');
    final keepTheme = prefs.getString('theme_mode');
    final keepLocale = prefs.getString('app_locale');
    await prefs.clear();
    if (keepUrl != null) await prefs.setString('api_base_url', keepUrl);
    if (keepTheme != null) await prefs.setString('theme_mode', keepTheme);
    if (keepLocale != null) {
      await prefs.setString('app_locale', keepLocale);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.localDataCleared)),
      );
    }
  }

  Future<void> _saveUrl() async {
    await ApiClient.setBaseUrl(_urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.apiServerUpdated)),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: context.l10n.morePrivacy,
              subtitle: context.l10n.privacySubtitle,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(context.l10n.localData),
                      Text(
                        context.l10n.localDataDesc,
                        style: TextStyle(color: context.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences
                                .getInstance();
                            await prefs.remove('cookie_consent_accepted');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(context.l10n
                                          .cookieConsentRevoked)));
                            }
                          },
                          child:
                              Text(context.l10n.revokeCookieConsent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _clearData,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(context.l10n.deleteAllData),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(context.l10n.thirdParties),
                      Text(
                        context.l10n.thirdPartiesDesc,
                        style: TextStyle(color: context.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Server API'),
                      Text(
                        context.l10n.apiServerDesc,
                        style: TextStyle(color: context.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: context.l10n.baseUrl,
                          hintText: 'https://actv-live.test',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveUrl,
                          child: Text(context.l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
